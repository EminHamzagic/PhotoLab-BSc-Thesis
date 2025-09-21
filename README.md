# PhotoLab – Image Processing Application in MATLAB

### Welcome to **PhotoLab**!

**PhotoLab** is a MATLAB application for image processing, designed to provide users with a simple and efficient way to manipulate images through an intuitive graphical user interface.
The main application window is `PhotoLab.mlapp`, which offers both basic and advanced image processing tools, as well as deep learning functionalities such as training and using Convolutional Neural Networks (CNNs).

---

## 📌 Core Features

### 🖼️ Image Processing

1. **Image loading and saving**

   * Supports popular formats such as JPEG, PNG, BMP, and more.
   * Save processed images in your desired format.

2. **Basic tools**

   * Resize images.
   * Rotate images.
   * Adjust brightness, contrast, and saturation.

3. **Advanced processing**

   * Apply filters (blur, sharpen, edge detection).
   * Convert images to grayscale.
   * Perform object detection and image segmentation.

4. **Before/After comparison**

   * Display the original and processed image side by side for easy comparison.

---

### 🤖 CNN Functionality

PhotoLab also allows training and using **Convolutional Neural Networks (CNNs)**.

1. **Architecture selection**

   * Choose from different CNN architectures to use during training.

2. **Dataset selection**

   * Download and use one of the available datasets directly from the application.

3. **Model training**

   * Configure training parameters (learning rate, batch size, epochs, optimizer, etc.).
   * Click **Start Training** to select a save location for your trained model and begin training.
   * Monitor **accuracy** and **loss** plots in real time.
   * Pause training at any time and save the model.

4. **Image classification**

   * Load a trained CNN model and an input image.
   * Click **Classify** to view classification results.

---

## 🚀 How to Run the Application

1. Open MATLAB.
2. Launch the app by opening `PhotoLab.mlapp`.
3. In the main window:

   * Load an image.
   * Choose a processing tool or CNN option.
   * Apply filters, transformations, or classification.

---

## ⚙️ System Requirements

### General Requirements

* **MATLAB R2021b or later** (recommended).
* **Image Processing Toolbox** (required for many image operations).
* **BM3D library** (if not included in your MATLAB installation).

👉 Download BM3D here: [BM3D.zip](https://webpages.tuni.fi/foi/GCF-BM3D/BM3D.zip)
After downloading:

1. Extract the ZIP file to a folder of your choice.
2. Add that folder to the **MATLAB path**.

---

### Additional Requirements for CNN Training & Deep Learning

If you want to train or use CNN models inside PhotoLab, you will need:

* **Deep Learning Toolbox** (essential for defining, training, and evaluating CNN architectures).
* **Parallel Computing Toolbox** (optional, but recommended for faster training using CPU parallelization).
* **GPU Coder Toolbox** (optional, for GPU acceleration and deployment).
* **Supported NVIDIA GPU** (optional but highly recommended for faster training):

  * CUDA-enabled NVIDIA GPU
  * Properly configured **CUDA Toolkit** and **cuDNN** libraries installed.

> ⚡ Training CNNs on CPU can be **very slow**. For best performance, use a GPU with CUDA support.

---

## ℹ️ Notes

PhotoLab is intended for **educational and research purposes** and may not be fully optimized for professional or production use.

---

## 📬 Contact

Author: **Emin Hamzagic**
📧 Email: [eminhamzagic7@gmail.com](mailto:eminhamzagic7@gmail.com)

---

✨ Enjoy image processing with **PhotoLab**!

