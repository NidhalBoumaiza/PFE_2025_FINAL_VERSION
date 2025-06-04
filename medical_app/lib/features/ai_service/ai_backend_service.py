import subprocess
from flask import Flask, request, jsonify
import PyPDF2
import os
import tempfile
from waitress import serve
import logging
from PIL import Image
import torch
import io

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger('ai_service')

# Flag to control whether to load the large Florence model
USE_FLORENCE = os.environ.get('USE_FLORENCE', 'True').lower() in ('true', '1', 't')

app = Flask(__name__)

# Initialize Florence model if enabled
if USE_FLORENCE:
    try:
        logger.info("Loading Florence-2 model...")
        from transformers import AutoProcessor, AutoModelForCausalLM
        
        MODEL_NAME = "microsoft/Florence-2-large"
        processor = AutoProcessor.from_pretrained(MODEL_NAME, trust_remote_code=True)
        model = AutoModelForCausalLM.from_pretrained(
            MODEL_NAME,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            trust_remote_code=True
        )
        if torch.cuda.is_available():
            model = model.eval().to("cuda")
        logger.info("Florence-2 model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load Florence-2 model: {e}")
        USE_FLORENCE = False

def get_chatbot_response(user_input: str) -> str:
    try:
        context = (
            "Vous êtes un assistant médical spécialisé en pharmacologie clinique. "
            "L'utilisateur recherche des informations sur les médicaments, leur posologie, "
            "les interactions, les effets indésirables et les bonnes pratiques d'utilisation. "
            "Fournissez des réponses précises et référencées lorsque possible. "
            "Mentionnez systématiquement que vos conseils ne remplacent pas l'avis d'un "
            "professionnel de santé qualifié."
        )
        prompt = f"{context}\n\nUtilisateur : {user_input}\nAssistant : "

        logger.info(f"Sending prompt to Gemma: {user_input[:50]}...")
        result = subprocess.run(
            ["ollama", "run", "gemma3:1b"],
            input=prompt,
            text=True,
            capture_output=True,
            encoding="utf-8",
            errors="ignore"
        )

        if result.returncode != 0:
            err = result.stderr.strip() if result.stderr else (result.stdout or "").strip()
            logger.error(f"Gemma error: {err}")
            return f"Erreur : {err}"

        response = (result.stdout or "").strip()
        logger.info(f"Received response from Gemma: {response[:50]}...")
        return response

    except Exception as e:
        logger.error(f"Error processing chat request: {e}")
        return f"Erreur : {str(e)}"

def get_pdf_summary(text: str) -> str:
    try:
        # Truncate text if it's too long
        if len(text) > 4000:
            text = text[:4000] + "..."
            
        prompt = f"Voici un extrait d'un document médical. Veuillez le résumer de façon concise :\n\n{text}\n\nRésumé :"
        
        logger.info("Sending PDF text to Gemma for summarization...")
        result = subprocess.run(
            ["ollama", "run", "gemma3:1b"],
            input=prompt,
            text=True,
            capture_output=True,
            encoding="utf-8",
            errors="ignore",
            timeout=60  # Add timeout to prevent hanging
        )
        
        if result.returncode != 0:
            err = result.stderr.strip() if result.stderr else (result.stdout or "").strip()
            logger.error(f"Gemma error during PDF summarization: {err}")
            return f"Erreur : {err}"
            
        response = (result.stdout or "").strip()
        logger.info(f"Received PDF summary from Gemma: {response[:50]}...")
        return response
    except subprocess.TimeoutExpired:
        logger.error("Gemma timed out during PDF summarization")
        return "Le modèle a mis trop de temps à répondre. Veuillez réessayer avec un document plus court."
    except Exception as e:
        logger.error(f"Error processing PDF: {e}")
        return f"Erreur : {str(e)}"

def run_example(task_prompt: str, image: Image.Image, text_input: str = None):
    """
    task_prompt: e.g. "<CAPTION>", "<DETAILED_CAPTION>", etc.
    image: a PIL Image
    text_input: optional extra text to append
    """
    if not USE_FLORENCE:
        return "Florence model not available"
        
    try:
        prompt = task_prompt + (text_input or "")
        logger.info(f"Analyzing image with prompt: {prompt}")
        
        inputs = processor(text=prompt, images=image, return_tensors="pt")
        if torch.cuda.is_available():
            inputs = {k: v.to("cuda", torch.float16) for k, v in inputs.items()}

        generated_ids = model.generate(
            input_ids=inputs["input_ids"],
            pixel_values=inputs["pixel_values"],
            max_new_tokens=1024,
            do_sample=False,
            num_beams=3,
        )

        generated_text = processor.batch_decode(generated_ids, skip_special_tokens=False)[0]
        parsed = processor.post_process_generation(
            generated_text,
            task=task_prompt,
            image_size=(image.width, image.height)
        )
        logger.info(f"Image analysis complete: {parsed[:50]}...")
        return parsed
    except Exception as e:
        logger.error(f"Error analyzing image: {e}")
        return f"Error analyzing image: {str(e)}"

def analyze_image_with_gemma(text_prompt: str) -> str:
    """
    Use Gemma to analyze an image based on text description.
    This is a fallback when Florence is not available.
    """
    try:
        context = (
            "Vous êtes un assistant médical spécialisé en analyse d'images médicales. "
            "Donnez des indications générales sur les éléments à rechercher dans une image correspondant à la description fournie."
            "Expliquez comment analyser l'image médicale décrite. "
            "Votre réponse doit être utile et instructive."
        )
        
        prompt = f"{context}\n\nDescription de l'image : {text_prompt}\n\nAnalyse suggérée :"
        
        logger.info(f"Using Gemma for image analysis based on description")
        result = subprocess.run(
            ["ollama", "run", "gemma3:1b"],
            input=prompt,
            text=True,
            capture_output=True,
            encoding="utf-8",
            errors="ignore",
            timeout=60
        )
        
        if result.returncode != 0:
            err = result.stderr.strip() if result.stderr else (result.stdout or "").strip()
            logger.error(f"Gemma error during image analysis: {err}")
            return f"Erreur : {err}"
        
        response = (result.stdout or "").strip()
        logger.info(f"Received image analysis from Gemma: {response[:50]}...")
        return response
    except subprocess.TimeoutExpired:
        logger.error("Gemma timed out during image analysis")
        return "Le modèle a mis trop de temps à répondre. Veuillez réessayer."
    except Exception as e:
        logger.error(f"Error analyzing image with Gemma: {e}")
        return f"Erreur : {str(e)}"

@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint to verify the service is running"""
    return jsonify({"status": "ok", "florence_available": USE_FLORENCE})

@app.route("/chat", methods=["POST"])
def chat():
    user_input = request.json.get("message")
    if not user_input:
        return jsonify({"error": "Message vide"}), 400
    
    logger.info(f"Chat request received: {user_input[:50]}...")
    response = get_chatbot_response(user_input)
    return jsonify({"response": response})

@app.route("/analyze-pdf", methods=["POST"])
def analyze_pdf():
    if 'pdf' not in request.files:
        return jsonify({"error": "Aucun fichier PDF fourni."}), 400
    
    pdf_file = request.files.get("pdf")
    logger.info(f"PDF analysis request received: {pdf_file.filename}")
    
    try:
        # Save the uploaded file to a temporary location
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
            pdf_file.save(temp_file.name)
            temp_filename = temp_file.name
        
        # Process the PDF
        reader = PyPDF2.PdfReader(temp_filename)
        full_text = ""
        for page in reader.pages:
            full_text += (page.extract_text() or "") + "\n\n"
            
        # Clean up the temporary file
        os.unlink(temp_filename)
        
        if not full_text.strip():
            return jsonify({"error": "Aucun texte trouvé dans le PDF."}), 400
            
        summary = get_pdf_summary(full_text)
        return jsonify({"summary": summary})
    except Exception as e:
        logger.error(f"Error analyzing PDF: {e}")
        return jsonify({"error": f"Erreur lors de l'analyse du PDF : {e}"}), 500

@app.route("/analyze-image", methods=["POST"])
def analyze_image():
    """
    Form-data POST:
    - image: file
    - task_prompt: string (e.g. "<CAPTION>")
    - text_input: optional
    Returns JSON with the parsed answer.
    """
    task_prompt = request.form.get("task_prompt", "<MEDICAL_ANALYSIS>")
    text_input = request.form.get("text_input", "Analyze this medical image and describe what you see.")
    
    logger.info(f"Image analysis request received with prompt: {task_prompt}")
    
    if not USE_FLORENCE:
        # Use Gemma as fallback with the text description
        logger.info("Florence not available, using Gemma for text-based analysis")
        result = analyze_image_with_gemma(text_input)
        return jsonify({"result": result}), 200
    
    if 'image' not in request.files:
        return jsonify({"error": "Aucun fichier image fourni."}), 400

    try:
        image_file = request.files["image"]
        img_data = image_file.read()
        img = Image.open(io.BytesIO(img_data)).convert("RGB")
    except Exception as e:
        logger.error(f"Error opening image: {e}")
        return jsonify({"error": f"Impossible d'ouvrir l'image : {e}"}), 400

    try:
        result = run_example(task_prompt, img, text_input)
        return jsonify({"result": result})
    except Exception as e:
        logger.error(f"Error during image analysis with Florence: {e}")
        # Fallback to Gemma
        logger.info("Florence analysis failed, falling back to Gemma")
        result = analyze_image_with_gemma(text_input)
        return jsonify({"result": result}), 200

def start_server(host='0.0.0.0', port=5000):
    """Start the Flask server with waitress for production"""
    logger.info(f"Starting AI service on {host}:{port}")
    logger.info(f"Florence model {'enabled' if USE_FLORENCE else 'disabled'}")
    serve(app, host=host, port=port)

if __name__ == "__main__":
    # Use this for development
    # app.run(debug=True, host='0.0.0.0', port=5000)
    
    # Use this for production
    start_server() 