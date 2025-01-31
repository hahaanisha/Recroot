# 🚀 Recroot - Seamless Applicant Tracking System (ATS)

**Recroot** is an advanced **Applicant Tracking System (ATS)** designed to streamline recruitment processes by automating **resume screening, job application tracking, interview scheduling, and offer letter management**.  

This documentation focuses on the **backend implementation, API development & deployment on Render, real-time database integration with Firebase, and resume storage using Cloudinary**.  

---

## 📌 Features  
✅ **ATS scoring** for resume-job description matching  
✅ **Job application tracking** for recruiters & candidates  
✅ **Automated interview scheduling** with notifications  
✅ **Smart feedback collection** from interviewers  
✅ **Offer letter management** and status tracking  
✅ **Resume storage on Cloudinary** for easy retrieval  
✅ **Real-time database on Firebase** for seamless data sync  

---

# ⚙️ Backend Overview  

## 🛠️ Tech Stack  

- **Backend Framework:** Flask  
- **Database:** Firebase (Real-time Database)  
- **Storage:** Cloudinary (Resume Storage)  
- **API Hosting:** Render  
- **Language:** Python  

---

## 👀 API Endpoints  

### 1️⃣ **Resume ATS Scoring API**  

**Endpoint:**  
```http
POST /ats-score
```
**Request Body (JSON):**  
```json
{
  "resume_url": "https://cloudinary.com/sample.pdf",
  "job_desc": "Software Engineer with experience in Python, Flask, and ML"
}
```
**Response (JSON):**  
```json
{
  "ats_score": 85.5
}
```
**Functionality:**  
- Downloads the resume from **Cloudinary**  
- Extracts text using **pdfplumber**  
- Computes similarity with **TF-IDF & Cosine Similarity**  
- Returns the **ATS Score**  

---

### 2️⃣ **Upload Resume to Cloudinary**  

**Endpoint:**  
```http
POST /upload-resume
```
**Request Body (Form Data):**  
- `resume_file`: (PDF file)  

**Response (JSON):**  
```json
{
  "resume_url": "https://res.cloudinary.com/.../resume.pdf"
}
```
**Functionality:**  
- Accepts a PDF file from the frontend  
- Uploads the resume to **Cloudinary**  
- Returns the **resume URL**  

---

### 3️⃣ **Job Application Data (Firebase Integration)**  

**Endpoint:**  
```http
POST /add-application
```
**Request Body (JSON):**  
```json
{
  "candidate_name": "John Doe",
  "email": "john@example.com",
  "job_role": "Software Engineer",
  "resume_url": "https://res.cloudinary.com/.../resume.pdf",
  "status": "Applied"
}
```
**Response (JSON):**  
```json
{
  "message": "Application added successfully"
}
```
**Functionality:**  
- Stores candidate job application data in **Firebase**  
- Tracks application **status updates** (Applied, Interview, Hired, Rejected)  

---

# 🚀 Deployment Guide  

## 1️⃣ Backend API Deployment on Render  

### **Step 1: Create a `requirements.txt` file**  
Ensure the following dependencies are added:  
```
flask
requests
pdfplumber
scikit-learn
firebase-admin
cloudinary
gunicorn
```

### **Step 2: Create a `render.yaml` file**  
```yaml
services:
  - type: web
    name: recroot-api
    runtime: python
    envVars:
      - key: CLOUDINARY_URL
        value: "your-cloudinary-url"
      - key: FIREBASE_CREDENTIALS
        value: "your-firebase-admin-sdk.json"
    buildCommand: "pip install -r requirements.txt"
    startCommand: "gunicorn index:app"
```

### **Step 3: Push the project to GitHub**  
```sh
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/your-repo/recroot
git push -u origin main
```

### **Step 4: Deploy on Render**  
- Go to [Render](https://render.com/)  
- Click on **"New Web Service"**  
- Select your GitHub repo  
- Set the runtime to **Python**  
- Add necessary **environment variables**  
- Click **Deploy**  

---

## 2️⃣ Firebase Integration  

### **Step 1: Setup Firebase**  
- Go to [Firebase Console](https://console.firebase.google.com/)  
- Create a **new project**  
- Go to **Project Settings → Service Accounts**  
- Generate a **Private Key JSON** and download it  

### **Step 2: Install Firebase Admin SDK**  
```sh
pip install firebase-admin
```

### **Step 3: Initialize Firebase in the Code**  
```python
import firebase_admin
from firebase_admin import credentials, db

cred = credentials.Certificate("firebase-admin-sdk.json")
firebase_admin.initialize_app(cred, {
    'databaseURL': "https://your-database-url.firebaseio.com/"
})
```

### **Step 4: Storing Job Applications in Firebase**  
```python
def store_application(data):
    ref = db.reference("/applications")
    ref.push(data)
    return {"message": "Application added successfully"}
```

---

# 🎨 Frontend Overview  

## **🖥️ UI Screens**  
✅ **Landing Page** - Displays job listings  
✅ **Upload Resume** - Candidates upload resumes  
✅ **ATS Score Page** - Shows matching score  
✅ **Dashboard** - Track job applications  

---

# 🏆 Conclusion  

Recroot is an **all in one hiring solution** that simplifies recruitment for companies. With **Cloudinary for resume storage, Firebase for real-time data, and Render for seamless API deployment**, Recroot is built for **scalability, efficiency, and automation**.  

🚀 **Get started today and make hiring hassle-free!**  

---

# 📌 Contact & Contribution  

👩‍💻 **Developed by:** [Tejas Gadge](https://github.com/tejasgadge2504)  
💡 **Contribute:** Fork the repo & submit a PR!  
📧 **Feedback/Suggestions:** Open an issue on GitHub  

---

**⭐ If you like this project, don’t forget to give it a star on GitHub! ⭐**  
