from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from ultralytics import YOLO
import os
from PIL import Image
import traceback
from fastapi.staticfiles import StaticFiles
import shutil

# Initialize FastAPI app
app = FastAPI()

app.mount("/output", StaticFiles(directory="output"), name="output")

# Path to your YOLOv8 model
MODEL_PATH = r"runs\detect\yolov8s-seg_EnviroScan_Results3\weights\best.pt"  # Update this with the actual path
if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Model file not found at {MODEL_PATH}")

# Load the YOLOv8 model
model = YOLO(MODEL_PATH)

# Function to return advice based on detected class
def _get_advice(class_name):
    advice_dict = {
        "Aluminium foil": "Clean and recycle if not contaminated with food.",
        "Battery": "Do NOT throw in regular trash! Take to a battery recycling facility.",
        "Blister pack": "Check if recyclable locally. Some pharmacies accept them.",
        "Bottle": "Rinse and place in plastic or glass recycling bin.",
        "Bottle cap": "Separate from the bottle and recycle in a plastic bin.",
        "Broken glass": "Handle carefully. Wrap in newspaper and dispose of safely.",
        "Can": "Rinse and recycle in the metal bin.",
        "Carton": "Flatten and recycle with paper or cardboard.",
        "Cup": "Check if recyclable; many paper cups are lined with plastic.",
        "Food waste": "Compost if possible; otherwise dispose in organic waste.",
        "Glass jar": "Rinse and recycle in the glass bin. Remove the lid first.",
        "Lid": "Recycle separately based on material (plastic or metal).",
        "Other plastic": "Check local recycling rules for mixed plastics.",
        "Paper": "Recycle in the paper bin. Keep dry for better processing.",
        "Paper bag": "Recycle or reuse if clean.",
        "Plastic bag & wrapper": "Do not put in bins! Take to a grocery store drop-off.",
        "Plastic container": "Rinse and recycle if accepted locally.",
        "Plastic gloves": "Not recyclable. Dispose of in regular trash.",
        "Plastic utensils": "Not recyclable in most places. Consider reusing.",
        "Pop tab": "Recycle with metal cans or donate to charities that accept them.",
        "Rope & strings": "Not recyclable. Dispose of safely to avoid tangling machines.",
        "Scrap metal": "Take to a scrap yard or metal recycling facility.",
        "Shoe": "Consider donating if in good condition. Not typically recyclable.",
        "Squeezable tube": "Difficult to recycle. Check local facilities.",
        "Straw": "Not recyclable. Dispose of in regular trash.",
        "Styrofoam piece": "Not recyclable in most places. Consider reuse or special facilities.",
        "Unlabeled litter": "Unknown material. Check with local waste management.",
        "Cigarette": "Dispose of in a cigarette waste bin. Harmful to the environment.",
    }
    return advice_dict.get(class_name, "No specific advice available for this item.")

@app.post("/analyze/")
async def analyze_images(files: list[UploadFile] = File(...)):
    results = []
    os.makedirs("output", exist_ok=True)  # Ensure output folder exists

    for file in files:
        try:
            # Load the image
            image = Image.open(file.file).convert("RGB")

            # Run YOLOv8 inference
            yolo_results = model(image)
            result = yolo_results[0]  # First result (since YOLO handles one image at a time)

            # Extract detections
            detections = []
            if result.boxes:
                for box in result.boxes:
                    class_id = int(box.cls)
                    class_name = result.names.get(class_id, "Unknown")
                    advice = _get_advice(class_name)  # Get advice for the detected class

                    detections.append({
                        "class": class_name,
                        "confidence": float(box.conf),
                        "coordinates": box.xyxy.tolist(),
                        "advice": advice  # Include advice
                    })

            # Save the annotated image
            annotated_image = result.plot()
            output_path = os.path.join("output", f"annotated_{file.filename}")
            annotated_image_pil = Image.fromarray(annotated_image)
            annotated_image_pil.save(output_path)

            # Add results for this image
            results.append({
                "image": f"/output/annotated_{file.filename}",
                "detections": detections
            })

        except Exception as e:
            print(f"Error processing {file.filename}: {e}")
            traceback.print_exc()

    return JSONResponse(content={"results": results})

@app.get("/clear-outputs/")
async def clear_outputs():
    folder = "output"
    if os.path.exists(folder):
        for file in os.listdir(folder):
            file_path = os.path.join(folder, file)
            try:
                os.remove(file_path) if os.path.isfile(file_path) else shutil.rmtree(file_path)
            except Exception as e:
                return {"error": f"Failed to delete {file}: {e}"}
    return {"message": "Output folder cleared successfully"}
