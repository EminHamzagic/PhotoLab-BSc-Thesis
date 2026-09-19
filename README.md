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

5. **Model evaluation**

   * Load a trained model in **Evaluacija metrika** to see accuracy, macro precision / recall / F1,
     a confusion matrix, per-class charts and the most frequent confusions.
   * Export the model's predictions to CSV.

6. **Generative models**

   * Train a Variational Autoencoder (VAE) and generate new images with it — see
     [Generativni modeli](#-generativni-modeli).

---

### 🧠 Supported Architectures and Why

PhotoLab's datasets (MNIST, Fashion-MNIST, CIFAR-10, CIFAR-100) are small, low-resolution
images (28×28 and 32×32) with 10–100 classes. The offered architectures were chosen to fit
that setting: both are trained from scratch, run at a reasonable speed on a CPU and need no
extra Add-Ons.

| Architecture | Mode | Why it fits low-resolution datasets |
|---|---|---|
| **LeNet-5** | Trained from scratch | Designed for 28×28 digit images; the natural baseline and fast on CPU. |
| **AlexNet (CIFAR-scale)** | Trained from scratch | Five conv + three FC layers sized for 32×32×3 color images: enough capacity for CIFAR while still trainable from scratch on a CPU. |

The network is built for the dataset's own image size, and the normalization chosen in the dataset
window applies to both.

**Architectures that were dropped:**

* **ResNet-18 / MobileNet-v2 / SqueezeNet** – transfer-learning networks that require pretrained-model
  Add-Ons and 224×224 (SqueezeNet: 227×227) inputs. They are out of scope for a project that has to run
  on a plain MATLAB install, but they remain a possible future extension.
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

## 🎨 Generativni modeli

PhotoLab can train a **Variational Autoencoder (VAE)** and use it to generate new images. The VAE is
currently the only generative model PhotoLab supports. It works on the small datasets prepared in the
dataset window: 28×28 grayscale (MNIST, Fashion-MNIST) and 32×32 colour (CIFAR-10) images.

### What a VAE is

A VAE learns to squeeze every training image into a short list of numbers, its **latent code**, and to
rebuild the image from that code. Unlike an ordinary autoencoder it does not learn one code per image
but a small cloud of likely codes, and it is pushed to keep all those clouds close to a standard bell
curve centred on zero. That makes the latent space smooth and well filled, so a code picked at random
decodes into a plausible new image. Training balances two goals: the rebuilt image should look like the
original (*reconstruction loss*, binary cross-entropy for grayscale or mean squared error), and the codes
should stay close to the bell curve (*KL loss*, weighted by **β**).

### How to train one

1. Open **Deep Learning za analizu slike → Treniranje generativnog modela**.
2. Choose a dataset that was downloaded in the dataset window (the folder must contain `photolab_dataset.mat`).
3. Set the parameters: latent dimension (how many numbers describe one image), epochs, batch size,
   learning rate, seed, the number of training images to use (0 = all; a few thousand is plenty for a
   first run on a CPU), β and the reconstruction loss.
4. Click **Započni treniranje** and choose where to save the model. The window plots the total,
   reconstruction and KL losses and shows a grid of images decoded from the *same* fixed random codes after
   every epoch, so you can watch the samples sharpen. **Zaustavi** stops after the current epoch and still
   saves the model.

Everything runs on the CPU (about 20 seconds per epoch for 10 000 MNIST images on a laptop).

### How to generate images

Open **Generisanje slika**, load the saved VAE file, choose how many images you want and a seed and click
**Generiši**. The same seed always gives the same images. **Sačuvaj grid (PNG)** saves the picture. A file
that is not a VAE model is rejected with an error message.

### Latent interpolation

Pick two random codes and walk in a straight line between them, decoding each step. The result is a row of
images that morphs smoothly from one to the other (a 3 slowly turning into an 8, say). Smooth transitions
without sudden jumps are a sign that the latent space is well organised. Use **Interpolacija** to see it.

### The 2-D latent manifold

If the model was trained with a latent dimension of 2, every image is one point on a plane. **Latentni
manifold** decodes a regular grid of points over [−3, 3] × [−3, 3] and lays the results out as a picture:
digits of the same kind form neighbouring regions and change gradually between them. It is the most direct way
to *see* what the model has learned. It is only available for latent dimension 2.

**Rekonstrukcija** (after choosing a dataset) shows random test images above their reconstructions, which works
for any latent dimension.

### Evaluation with a classifier

How do you know whether generated images are any good? One practical answer is to ask a classifier. In the
**Evaluacija klasifikatorom** tab, load a classifier trained in PhotoLab (ideally on the same dataset — the
window warns if the datasets differ) and click **Evaluiraj**. PhotoLab generates N images (1000 by default),
feeds them to the classifier the same way its own training images were fed, and reports a histogram of the
predicted classes and the **mean confidence** (the average of the classifier's highest class probability).
Confident, varied predictions suggest the images look like real, distinct classes; a histogram with one tall
bar suggests the VAE keeps producing the same thing.

### Simplified Inception Score

The Inception Score rewards a generator whose images are (a) clearly recognisable and (b) varied. For every
generated image the classifier gives class probabilities *p(y|x)*; averaged over all images they give the
overall class mix *p(y)*. The score is

`IS = exp( mean over images of KL( p(y|x) ‖ p(y) ) )`

It equals 1 when the classifier is unsure about every image or predicts the same class for all of them, and
reaches the number of classes (10 for MNIST) when every image is classified confidently and all classes
appear equally often. It is *simplified* because it uses a PhotoLab classifier instead of the Inception-v3
network of the original metric, so scores are only comparable between runs that use the same classifier.

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
* **Wavelet Toolbox** (used by image fusion).
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

* **Deep Learning Toolbox** (essential for defining, training, and evaluating CNN architectures and the VAE).
* **Parallel Computing Toolbox** (required for GPU training).
* **Supported NVIDIA GPU** (optional but highly recommended for faster training):

  * CUDA-enabled NVIDIA GPU with compute capability **5.0 or higher** (R2023b).
  * An up-to-date NVIDIA driver (MATLAB ships its own CUDA/cuDNN libraries).

The training window detects the GPU on startup. The **Koristi GPU** option is enabled only when a
usable GPU is found, and it shows the GPU model and compute capability. AMD, Intel and Apple Silicon
GPUs are not supported by `trainNetwork`; on those machines training runs on the CPU.

> ⚡ Training CNNs on CPU can be **very slow**. For best performance, use a GPU with CUDA support.
>
> No pretrained-model Add-Ons are needed. The VAE is small and is meant to be trained on a CPU.

---

## ℹ️ Notes

PhotoLab is intended for **educational and research purposes** and may not be fully optimized for professional or production use.

---

## 📬 Contact

Author: **Emin Hamzagic**
📧 Email: [eminhamzagic7@gmail.com](mailto:eminhamzagic7@gmail.com)

---

✨ Enjoy image processing with **PhotoLab**!

