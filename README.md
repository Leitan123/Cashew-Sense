# **An Integrated Smart System for Cashew Cultivation**
Project ID: 25-26J-175

Research Area: Smart Agriculture

Location: Sri Lanka (Focused on North Western Province)

## 📌 Project Overview
Our system presents an end-to-end smart solution designed to modernize cashew farming by addressing key challenges in soil management, disease control, pest identification, and post-harvest quality grading. The system leverages Artificial Intelligence (AI), Machine Learning (ML), and Computer Vision to empower farmers with real-time, data-driven insights, reducing dependency on manual labor and costly laboratory testing.
The system aims to reduce a 30-40% annual yield loss caused by undetected pests/diseases and increase market profitability through standardized nut grading.

## **System Objetives**
- Optimize Soil Fertility:- To provide real-time NPK and moisture monitoring via IoT sensors for precise fertilizer recommendations.
- Automate Disease Management:- To use CNN-based image recognition for early identification of the top 3 cashew diseases and provide instant remedies.
- Enhance Pest Control:- To implement YOLOv8 object detection for accurate pest identification and targeted control strategies.
- Standardize Nut Quality:- To objectively grade cashew nuts (Grade A/B/C) using computer vision (YOLOv8n) and physical parameters like density and weight.
- Rural area usage through the offline system design.
- Centralize Farm Operations:- To integrate hardware (ESP32) and complex AI models into a single, user-friendly Flutter mobile application via a Flask API.
- Increase Productivity:- To empower farmers with data-driven insights that reduce crop loss and maximize harvest market value.


## 🏗 **System Architecture**
<img width="1336" height="1024" alt="image" src="https://github.com/user-attachments/assets/b99bbf46-3258-4ef8-bfa8-64208b057657" />


## 🚀 Key Components
### 1. Smart Soil Health Analysis & Decision Support : Mithushh P (IT22180902)

**Scope**
- Predicts Soil health by analyzing NPK levels(Nitrogen,Phosporus,Pottasium),temperature and moisture using IOT device.
- Analyse the plant growth using images and suggesting the fertilizer levels.

**Functionality**
- Replaces expensive lab tests with on-site mobile analysis and provides specific fertilizer recommendations and varietal matching for optimized planting.
---
### 2. Automated Grading System for Cashew Nuts : Sanoch M (IT22159694)

**Scope**
- Computer-vision-based classification of harvested nuts.

**Functionality**
- Uses CNNs to grade nuts into A,B,C based on international categories (e.g., W180, W210), physical mesurements(length,width,density,weight) and ensuring fair market value and export readiness.
---
### 3. Cashew Leaf Disease Detection AI Model : Thimothy K L (IT22206428)

**Scope**
- Early identification of diseases on cashew plants.

**Functionality**
- Two-stage CNN architecture: Binary classification (healthy vs. diseased) followed by multi-class classification.
- Identifies specific diseases such as **Anthracnose**,**Leaf Miner**,**Red Rust**, and **Leaf Spot**.
---
### 4. Cashew Pest Identification System : Usman M.H (IT22351104)

**Scope**
- providing a real-time, AI-driven solution for detecting and managing pests in cashew plantations.
  
**Functionality**
- Real-time detection of small pests such as **Red Mite**,**Stem Borer**,**Thrips** even in complex farm backgrounds.
- Explainable AI through Grad-CAM visualization to highlight the specific regions influencing the detection.
- Sustainable management recommendations, prioritizing eco-friendly and organic control methods.
---

## 🛠 **Tech Stack**

**Programming Language** 
- Python 

**Hardware Components**
- ESP32
- RS-485
- NPK 7 in 1 sensor

**AI/ML Frame works,Libraries,Models**
- Deep Learning
  - TensorFlow
  - Keras
  - PyTorch
  - YOLOv8
  - YOLOv8n
  - OpenCV
  - Random forest
  - Dense neural network
  - Scikit-learn (for regression/soil health models)

**Development Workspace/IDE**
- PyCharm IDE
- Google Colab

**Mobile App / Frontend** 
- Flutter / React Native

**Backend API**
- FastAPI / Flask

**Database/Cloud**
- Firebase (Real-time DB & Auth)
- Google Cloud Platform (Model Hosting)


The system follows a centralized cloud-processing flow:

Data Acquisition: Images/Data captured via smartphone camera/sensors.

Preprocessing: Image resizing, noise reduction, and color normalization.

Inference: AI models hosted on the cloud process the data.

Actionable Insight: Results (Fertilizer dosage, Disease name, Pest alert, Nut grade) sent back to the farmer's mobile UI.

---

## **Contributors**
1. Mithushh P (IT22180902) :- Smart Soil Health Analysis & Decision Support
2. Sanoch M (IT22159694) :- Automated Grading System for Cashew Nuts
3. Thimothy K L (IT22206428) :- Cashew Leaf Disease Detection
4. Usman M.H (IT22351104) :- Cashew Pest Identification System
---

## **Research Content**
The Integrated Smart System for Cashew Cultivation (Project ID: 25-26J-175) is a SLIIT research initiative designed to modernize cashew farming using AI, Machine Learning, and Computer Vision. This end-to-end solution addresses critical gaps in traditional agriculture by providing real-time, data-driven insights through four specialized modules. Mithushh P developed the Smart Soil Health Analysis system to estimate nitrogen and moisture levels via smartphone imagery, offering tailored fertilizer recommendations. Thimothy K L engineered the Leaf Disease Detection AI Model, utilizing a two-stage CNN for mobile-based diagnosis of foliar diseases like Anthracnose. Usman M.H created the Agri Doc Pest Identification System, which employs YOLOv8 and Grad-CAM to detect minute pests such as the Tea Mosquito Bug. Finally, Sanoch M developed the Automated Nut Grading System, which uses vision-based density estimation to classify nut quality objectively. Built with a tech stack featuring Python, TensorFlow, PyTorch, and OpenCV, the system promotes sustainable, high-yield agriculture by solving complex technical hurdles like small-object detection and sensor-free soil diagnostics.

