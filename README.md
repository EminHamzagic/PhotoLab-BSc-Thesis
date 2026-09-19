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

### 🧠 Supported Architectures and Why

PhotoLab's datasets (MNIST, Fashion-MNIST, CIFAR-10, CIFAR-100) are small, low-resolution
images (28×28 and 32×32) with 10–100 classes. The offered architectures were chosen to fit
that setting:

| Architecture | Mode | Why it fits low-resolution datasets |
|---|---|---|
| **LeNet-5** | Trained from scratch | Designed for 28×28 digit images; the natural baseline and fast on CPU. |
| **AlexNet (CIFAR-scale)** | Trained from scratch | Five conv + three FC layers sized for 32×32×3 color images: enough capacity for CIFAR while still trainable from scratch on a CPU. |
| **ResNet-18** | Transfer learning | The shallowest residual network; skip connections prevent degradation, and it is the cheapest ResNet to fine-tune. |
| **MobileNet-v2** | Transfer learning | Depthwise-separable convolutions give good accuracy at a very low FLOP count. |
| **SqueezeNet** | Transfer learning | Only ~1.2M parameters; the fastest pretrained option. |

The pretrained networks need 224×224×3 (SqueezeNet: 227×227×3) input. Training resizes the images
and converts grayscale to RGB on the fly, so any dataset works with any architecture. The pretrained
networks keep their own ImageNet input normalization; the normalization chosen in the dataset window
applies to LeNet and AlexNet.

Pretrained networks require the corresponding free Add-Ons (Home → Add-Ons → Get Add-Ons):
*Deep Learning Toolbox Model for ResNet-18 Network*, *… for MobileNet-v2 Network*, *… for SqueezeNet Network*.

**Architectures that were dropped:**

* **VGG-16 / VGG-19** – ~138M parameters and a hard 224×224 input requirement; far too heavy for 32×32 data.
* **ResNet-50** – about 4× the compute of ResNet-18 for little gain on low-resolution images.
* **Inception-v3** – needs 299×299 input, i.e. more than 9× upsampling of a 32×32 image.
* **EfficientNet** – its compound scaling is tuned for high-resolution inputs.
* **YOLOv4** – an object detector, not a classifier; it does not fit a folder-per-class classification workflow.

### 🗂️ Datasets and Preprocessing

* The image size chosen in the dataset window is applied **at download time**, and every size gets its
  own folder (e.g. `datasets/MNIST_28x28`, `datasets/MNIST_32x32`).
* Normalization (`None`, `MinMax`, `Mean-Std`) is stored in the network's input layer. The saved model
  therefore applies exactly the same transform when classifying new images.
* Each prepared dataset contains a `photolab_dataset.mat` manifest (image size, channels, class names).

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

* **MATLAB R2023b or later** (recommended).
* **Image Processing Toolbox** (required for many image operations).
* **BM3D library** (if not included in your MATLAB installation).

👉 Download BM3D here: [BM3D.zip](https://webpages.tuni.fi/foi/GCF-BM3D/BM3D.zip)
After downloading:

1. Extract the ZIP file to a folder of your choice.
2. Add that folder to the **MATLAB path**. If you skip this, PhotoLab looks for a `BM3D` folder on your
   Desktop (and next to the repository) the first time you use the BM3D filter, and asks you to pick the
   folder if it finds none.

This is the original Tampere release (`[PSNR, y_est] = BM3D(y, z, sigma, ...)`, grayscale only, with
`CBM3D` for RGB, `sigma` on the 0–255 scale). Two demo images for trying the denoising filters are in
`+SampleImages/` (`demo_bricks_256.png`, `demo_gradient_256.png`).

---

### Additional Requirements for CNN Training & Deep Learning

If you want to train or use CNN models inside PhotoLab, you will need:

* **Deep Learning Toolbox** (essential for defining, training, and evaluating CNN architectures).
* **Parallel Computing Toolbox** (required for GPU training).
* **Supported NVIDIA GPU** (optional but highly recommended for faster training):

  * CUDA-enabled NVIDIA GPU with compute capability **5.0 or higher** (R2023b).
  * An up-to-date NVIDIA driver (MATLAB ships its own CUDA/cuDNN libraries).

The training window detects the GPU on startup. The **Koristi GPU** option is enabled only when a
usable GPU is found, and it shows the GPU model and compute capability. AMD, Intel and Apple Silicon
GPUs are not supported by `trainNetwork`; on those machines training runs on the CPU.

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

