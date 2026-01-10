Agri Doc: An Integrated Smart System for Cashew Cultivation
Project ID: 25-26J-175

Research Area: Smart Agriculture / Precision Farming

Location: Sri Lanka (Focused on North Western Province)

📌 Project Overview
Agri Doc is a holistic AI-driven mobile ecosystem designed to revitalize the cashew industry in Sri Lanka. By integrating soil health analysis, plant protection (pest and disease detection), and automated post-harvest grading, the system empowers farmers to move from traditional "guesswork" to data-driven precision agriculture.

The system aims to reduce a 30-40% annual yield loss caused by undetected pests/diseases and increase market profitability through standardized nut grading.

🚀 Key Components
1. Smart Soil Health Analysis & Decision Support
Lead: Mithushh P (IT22180902)

Focus: Predicts Nitrogen (N) levels by analyzing soil color, texture, and moisture.

Functionality: Replaces expensive lab tests with on-site mobile analysis and provides specific fertilizer recommendations and varietal matching for optimized planting.

2. Automated Grading System for Cashew Nuts
Lead: Sanoch M (IT22159694)

Focus: Computer-vision-based classification of harvested nuts.

Functionality: Uses CNNs to grade nuts into international categories (e.g., W180, W210) based on size, shape, and surface health, ensuring fair market value and export readiness.

3. Cashew Leaf Disease Detection AI Model
Lead: Thimothy K L (IT22206428)

Focus: Early identification of fungal and bacterial pathogens.

Functionality: Detects diseases such as Anthracnose and Red Rust using a two-stage CNN classifier optimized for low-resource mobile devices.

4. Integrated Pest Identification System
Lead: Usman M.H (IT22351104)
# Cashew Pest Detection System 🌱🐛

An end-to-end **AI-powered pest detection system for cashew plants** using the **YOLOv8 deep learning model**, deployed as a **REST API** with **mobile and web interfaces** to support real-time, eco-friendly pest management.

---

## 🚀 Features

- **YOLOv8 Object Detection**  
  State-of-the-art deep learning model optimized for real-time and small pest detection.

- **Grad-CAM Visualization (Explainable AI)**  
  Highlights image regions that influenced predictions, improving transparency and farmer trust.

- **Real-Time Detection**  
  Fast inference suitable for field-level usage (≤ 5 seconds per image).

- **Eco-Friendly Recommendations**  
  Provides pest control guidance prioritizing organic and biological methods before chemical treatments.

- **Multi-Platform Support**  
  Accessible via Web and Mobile applications.

- **Roboflow Integration**  
  Efficient dataset labeling, augmentation, and version control.

- **Small Object Optimization**  
  Enhanced preprocessing and multi-scale detection for tiny insects (< 2 pixels).

---

## 🐜 Supported Pests

This system is specialized for detecting **three critical cashew pests**:

### 1. Red Mite (*Oligonychus coffeae*) – **HIGH Severity**
- Size: 0.3–0.5 mm  
- Damage: Leaf bronzing, reduced photosynthesis, leaf drop  
- Conditions: Hot and dry climates  
- Detection Challenge: Extremely small size

### 2. Stem Borer (*Plocaederus ferrugineus*) – **HIGH Severity**
- Damage: Tunnels into stem and roots  
- Symptoms: Wilting, branch dieback, plant death  
- Detection Challenge: Partial visibility and occlusion

### 3. Thrips (*Scirtothrips dorsalis*) – **MEDIUM Severity**
- Size: 1–2 mm  
- Damage: Leaf curling, fruit scarring  
- Lifecycle: 12–15 generations per year  
- Detection Challenge: Rapid movement and clustering

---

## 🧠 System Architecture

1. Image capture via mobile camera or upload  
2. Image preprocessing (resize, normalization, enhancement)  
3. YOLOv8-based pest detection  
4. Grad-CAM heatmap generation  
5. Pest classification and localization  
6. Eco-friendly treatment recommendation  
7. Results displayed on web/mobile UI  

---

## 🛠️ Technology Stack

### AI & Computer Vision
- **YOLOv8**
- **Grad-CAM**
- **OpenCV**
- **Pillow (PIL)**

### Backend
- **Python**
- **Flask (REST API)**

### Frontend
- **React.js**
- **HTML / CSS / JavaScript**

### Dataset & Training
- **Custom Cashew Pest Dataset**
- **Roboflow** (annotation & augmentation)

Focus: Real-time detection of minute pests like the Stem Borer and Tea Mosquito Bug.

Functionality: Utilizes YOLOv8 for high-speed object detection and incorporates Grad-CAM (Explainable AI) to visualize detection zones for increased farmer trust.

🛠 Tech Stack
Programming & Frameworks:

Language: Python 3.x

Deep Learning: TensorFlow, Keras, PyTorch

Object Detection: YOLOv8 (You Only Look Once)

Computer Vision: OpenCV

Machine Learning: Scikit-learn (for regression/soil health models)

Mobile & Backend:

Mobile App: Flutter / React Native

Backend API: FastAPI / Flask

Database/Cloud: Firebase (Real-time DB & Auth), Google Cloud Platform (Model Hosting)

Tools & Visualization:

XAI: Grad-CAM (Gradient-weighted Class Activation Mapping)

Development: Google Colab, Jupyter Notebooks

🏗 System Architecture
The system follows a centralized cloud-processing flow:

Data Acquisition: Images/Data captured via smartphone camera/sensors.

Preprocessing: Image resizing, noise reduction, and color normalization.

Inference: AI models hosted on the cloud process the data.

Actionable Insight: Results (Fertilizer dosage, Disease name, Pest alert, Nut grade) sent back to the farmer's mobile UI.

