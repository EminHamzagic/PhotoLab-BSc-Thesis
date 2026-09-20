# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this project is

PhotoLab is a **MATLAB App Designer** desktop application for image processing, CNN-based image
classification and VAE-based image generation, built as a university (Fakultet) project. It is a
collection of `.mlapp` GUI apps plus plain `.m` helper functions — there is no build system, no
package manager, and no test suite. Everything runs inside MATLAB.

- **Target MATLAB release:** R2023b (see `resources/appDesigner.json`); the code has also been
  built and smoke-tested on R2025b.
- **Required toolboxes:** Image Processing Toolbox; Deep Learning Toolbox (for the CNN and VAE
  halves); Wavelet Toolbox (`dwt2`/`idwt2`, used by image fusion); optionally Parallel Computing
  (GPU). **Nothing depends on pretrained-model Add-Ons**, and everything is meant to run at a
  reasonable speed on a CPU (the reference machine is an Intel i5 with 16 GB RAM and no NVIDIA GPU).
- **External dependency:** the BM3D library must be downloaded separately and added to the
  MATLAB path (see `README.md`) — `utils/bm3dDenoise.m` wraps it, and `utils/ensureBM3D.m` finds the
  folder and runs `addpath` + `savepath`. It is the **legacy** release:
  `[PSNR, y_est] = BM3D(y, z, sigma, profile, print_to_screen)` (`y` = clean reference, `1` if none;
  grayscale only; `CBM3D` for RGB) with `sigma` on the **0–255** scale, not 0–1.
- **UI language:** Serbian/Bosnian (Latin script). Component names are derived from Serbian
  labels with diacritics stripped, which is why identifiers look mangled
  (`UitajslikuButton` = "Učitaj sliku", `DodavanjeumairazliitifilteriButton` =
  "Dodavanje šuma i različiti filteri"). Keep new UI strings in the same language. Components
  added in the newer windows (the two generative apps, `EvaluationMetricsApp`) use plain English
  identifiers instead; either is fine, but stay consistent within one file.
  Code comments are a mix of Serbian and English.
- **Generative models:** **the project currently supports the VAE as its only generative
  architecture.** No other generative architecture is implemented, and none should be added
  without a deliberate decision (see "Generative models" below).

## Running it

Open MATLAB in the repo root and launch `PhotoLab.mlapp`. Both buttons on the main screen call
`addpath` on `cnn_ui`, `options_ui`, `scripts`, `metrics`, `generative`, `cnn_core` and `utils`, then
`savepath`, so the helper folders only become visible after the app has been opened once.
`cnn_Menu` also adds them in its `startupFcn` (without `savepath`), so it works when opened
directly. If you call helper functions directly from the MATLAB console, add those paths yourself.

**GUI vs. headless.** The GUIs themselves can only be clicked through by the user inside MATLAB.
Everything below the GUI can be run headlessly with `matlab -batch "<code>"` (on the author's
machine MATLAB is at `D:\MatLab\bin\matlab`): rebuilding apps with `mlappFromSource`, calling any
function in `generative/`, `metrics/` or `utils/`, and even driving an app object programmatically
(instantiate it, set state, invoke its callbacks) and exporting a screenshot with `exportapp`.
Use that to verify changes before asking the user to test them by hand. Note `-batch` cannot define
functions inline; put test code in a script file with local functions.

## Directory layout

```
PhotoLab/
├── PhotoLab.mlapp            Main entry window (menu). Two buttons: image processing / deep learning.
├── Options.mlapp             Image-processing hub (menu). Loads ONE image, hands it to child apps.
├── cnn_Menu.mlapp            Deep-learning hub (menu). Holds selected architecture + dataset state.
├── options_ui/               Child apps for classic image-processing operations.
├── cnn_ui/                   Child apps for the CNN and VAE workflows.
├── generative/               Plain .m functions of the VAE (networks, loss, training loop, generation, evaluation).
├── cnn_core/                 Plain .m functions of the CNN training pipeline, shared by TrainingCNN and experiments/.
├── experiments/              Unattended thesis experiment scripts (plan, runner, benchmark, VAE runs, figures).
├── mlapp_src/                Readable copies of the code embedded in every .mlapp except CNNIntroductionApp.
├── tools/                    Dev tooling: mlappFromSource.m rebuilds an .mlapp from mlapp_src/;
│                             makeFilterDemoImages.m regenerates the two denoising demo PNGs.
├── scripts/                  Dataset download + preparation functions (plain .m).
├── metrics/                  Classification metrics + model evaluation helpers (plain .m).
├── utils/                    Denoising helpers (blockMatchingDenoise, bm3dDenoise, ensureBM3D,
│                             addGaussianNoise, estimateNoiseSigma).
├── +SampleImages/            Thumbnail images shown in the dataset browser (+ two denoising demo PNGs).
├── resources/appDesigner.json  App Designer custom-component metadata (auto-generated).
└── datasets/                 NOT in git (.gitignore). Created at runtime by the dataset app.
```

## App architecture

Everything is a `matlab.apps.AppBase` subclass in App Designer format. `.mlapp` files are ZIP
archives; the MATLAB code lives in `matlab/document.xml` inside them as a single CDATA block
(real LF newlines). To *read* the code of an app, unzip it and extract the CDATA section.

**Two copies of every app.** An `.mlapp` holds its code twice: in `matlab/document.xml` (what
MATLAB *runs*) and in the binary design model `appdesigner/appModel.mat` (what App Designer
*opens*). App Designer rebuilds `document.xml` from `appModel.mat` whenever it saves. So rewriting
only `document.xml` works until someone opens and saves the app in App Designer, which silently
reverts it to the old code.

**Editing without App Designer.** Every app except `CNNIntroductionApp` (static text, no logic) has
a readable copy in `mlapp_src/<App>.m`. To change one outside App Designer, edit
`mlapp_src/<App>.m` and rebuild the whole `.mlapp` (design model + code) with
`tools/mlappFromSource.m`:

```matlab
addpath tools
mlappFromSource('mlapp_src/TrainingCNN.m', 'cnn_ui/TrainingCNN.mlapp')
mlappFromSource('mlapp_src/Filters.m', 'options_ui/Filters.mlapp')
mlappFromSource('mlapp_src/PhotoLab.m', 'PhotoLab.mlapp')   % root-level apps too
```

It can also **create a brand-new `.mlapp`** from a source file (the target need not exist), so new
windows do not have to be started in App Designer. To verify a rebuild, read the embedded code back
with `appdesigner.internal.serialization.FileReader(file).readMATLABCodeText()` and compare it to the
source. On Windows every rebuild prints a harmless
`Temporary folder appDesignerTempData_… could not be deleted` warning.

Anything that is not a plain `app.X = ...;` statement (e.g. `title(app.UIAxes, ...)`) belongs in
`startupFcn`, not `createComponents`. Long algorithm code belongs in `utils/`, `metrics/` or
`generative/`, not in a callback.

It parses the App Designer layout (component properties block, editable sections, callbacks,
`startupFcn`, `createComponents`) and saves with App Designer's own
`appdesigner.internal.serialization.MLAPPSerializer`. It keeps the app's metadata/uuid. It only
understands App Designer-generated structure: `createComponents` must contain only `app.X = ...` /
`app.X.Prop = ...` statements, one per line (no local variables, no loops), and callbacks must be
one-level `function Name(app, event)` methods. Every component created there must also be declared
in the `properties` block. Helper methods go in a `methods` block *before* the
`% Callbacks that handle component events` block. It uses internal (undocumented) MATLAB APIs verified
on R2023b and R2025b.

**Do not save these apps from App Designer.** Opening an app and saving it rewrites the `.mlapp`
(reordered property list, default values such as `FontSize = 12` dropped, comments lost). The
behaviour is the same but the file no longer matches `mlapp_src/`. If an app is edited in App
Designer on purpose, copy its code back into `mlapp_src/<App>.m` so the two stay in sync. Never put
`mlapp_src/` or `tools/` output on the MATLAB path next to the apps: `mlapp_src` classdefs have the
same names as the `.mlapp` apps.

Two parent→child patterns are used, and they are inconsistent — match whichever one the file
you are editing already uses:

1. **`loadImage` push** (all of `options_ui/`): `Options` reads an image once into
   `app.ImageFile`, then does `child = ChildApp(); child.loadImage(app.ImageFile);`. Child apps
   expose a public `loadImage(app, image)` method and store it in `app.LoadedImage`.
   `ImageFusion` is the exception — it loads its own two images.
2. **`ParentApp` + `uiwait`/`uiresume`** (`cnn_Menu` → `CNNArchitectures`, `DatasetManagerApp`):
   the child gets a `ParentApp` reference and a public result property (`choosenArch`,
   `choosenDataset`, `setDimensions`, `setNormalization`); the parent blocks on
   `uiwait(child.UIFigure)`, reads the property, then `delete(child)`. The child must not call
   `uiwait` itself; it only calls `uiresume` once it has a result.

The remaining CNN windows are opened stand-alone (`ImageClassificationApp()`,
`EvaluationMetricsApp()`, `ImageGeneratingModelTraining()`, `ImageGeneratingFromModel()`); they load
everything they need themselves. `ImageClassificationApp` and `EvaluationMetricsApp` keep their
state in `app.UIFigure.UserData` (e.g. `SelectedModel`, `TestImageFiles`, `Results`, `Net`, `YTrue`,
`YPred`, `DatasetPath`); keep using `UserData` there rather than introducing new properties. The
two generative windows and `TrainingCNN` use private properties instead.

Guard clauses for missing input are `uialert(app.UIFigure, 'Morate izabrati sliku prvo!', 'Warning')`
style — keep that convention.

## `options_ui/` — image processing

| File | What it does |
|---|---|
| `ColorFormatsConversion.mlapp` | RGB ↔ HSV / CIELab / YCbCr via `rgb2hsv`, `rgb2lab`, `rgb2ycbcr`; can save result. |
| `GreyScaleConversion.mlapp` | `rgb2gray`. |
| `HistogramEqualization.mlapp` | `histeq` applied per R/G/B channel. |
| `ImageRotation.mlapp` | Live `imrotate(..., 'bilinear', 'crop')` driven by a slider. |
| `ResizingResampling.mlapp` | `imresize` with nearest/bilinear/bicubic; width/height or scale factor; rounds dimensions up to even numbers. |
| `Filters.mlapp` | Adds Gaussian (`addGaussianNoise`) or salt & pepper noise, stores the noisy image in `NoisyData` and the applied σ (0–255) in an editable field, then one radio group selects: median (`medfilt2` per channel), Gaussian (`imgaussfilt`), `blockMatchingDenoise` (vectorised block matching + 3-D DCT hard threshold), or `bm3dDenoise` (`CBM3D`/`BM3D`). Shows PSNR of the noisy and filtered image. BM3D/block matching assume Gaussian noise; after salt & pepper the app offers median instead. |
| `WienerFilter.mlapp` | Converts to grayscale, then `deconvwnr` with a 3×3 PSF and an NSR value. |
| `ActiveContours.mlapp` | Builds a Rectangle or Ellipse mask, shows it as a red alpha overlay, then runs `activecontour(..., 'Chan-Vese')` with slider-controlled iterations and SmoothFactor. |
| `HarrisCornerDetectionFeature.mlapp` | Harris response computed by hand (gradients → `imgaussfilt` on Ix², Iy², IxIy) with a threshold slider. |
| `ImageFusion.mlapp` | Loads two images itself, resizes to the common minimum, then per channel: `dwt2` (haar) → min of approximation coeffs, max of detail coeffs → `idwt2`. Can save the fused image. |

## `cnn_ui/` — deep learning

| File | What it does |
|---|---|
| `CNNIntroductionApp.mlapp` | Static explanatory text + MathWorks hyperlinks. No logic. No `mlapp_src` copy. |
| `CNNArchitectures.mlapp` | Table of the 2 architectures (LeNet, AlexNet) built from a struct array (`getArchitecturesData`). Selecting any cell in a row sets `choosenArch` from column 1. Only the name string is returned; it must match a `case` in `cnn_core/getLayers`. |
| `DatasetManagerApp.mlapp` | MNIST / Fashion-MNIST / CIFAR-10 / CIFAR-100. Resize dropdown (`WxH` entries parsed with `sscanf`; `Custom` adds a new `WxH` entry), normalization dropdown (`None`/`MinMax`/`Mean-Std`), preview, real class counts (`countEachLabel`) once downloaded. One download path driven by `getDatasetConfig`. Returns `choosenDataset` (path to `datasets/<Name>_<W>x<H>`), `setDimensions` (`[H W C]`) and `setNormalization`. |
| `TrainingCNN.mlapp` | Receives `(architecture, dataset, dimensions, normalization)` via `loadData`, builds layers, trains with a validation split, evaluates on `testing/`, saves (including the test predictions). Optional GPU. |
| `ImageClassificationApp.mlapp` | Load a `.mat` model (finds `net` or any `SeriesNetwork`/`DAGNetwork`), one image or a folder (`imageDatastore`), classify everything in one `classify` call. Results `uitable`; selecting a row shows the image and a top-5 table. Class names come from the saved `classNames` / the output layer. |
| `EvaluationMetricsApp.mlapp` | Workflow window (1200×760). **Main input: a trained model `.mat`.** If it holds `yTrue`/`yPred` they are used directly; older models without them need a dataset folder (must contain `photolab_dataset.mat`) whose `testing/` split is classified with `metrics/evaluateModelOnTestSet` using the same preprocessing as training. `yTrue`/`yPred` can still be imported from `.csv`/`.mat` (secondary button) and exported to CSV. Shows accuracy and macro precision/recall/F1 as 20 pt readouts, a confusion matrix (`imagesc`, counts drawn for ≤12 classes), a per-class Precision/Recall/F1 bar chart and a table of the most frequent confusions (`metrics/topConfusions`). No fallback model and no random data. |
| `ImageGeneratingModelTraining.mlapp` | **"Treniranje generativnog modela"** (1200×760). Trains a VAE (only) with `generative/trainGenerativeModel`. Left: dataset picker (only folders with `photolab_dataset.mat` and a supported size), common parameters (latent dimension, epochs, batch size, learning rate, seed, number of training images — 0 = all) and VAE parameters (β, BCE/MSE). Right: live total / reconstruction / KL loss curves and a grid of samples decoded from a **fixed** latent matrix, refreshed every epoch. `Započni treniranje` asks for the save path first; `Zaustavi` stops after the current epoch and still saves; `setBusy` locks the inputs. Closing the window mid-training only requests a stop. |
| `ImageGeneratingFromModel.mlapp` | **"Generisanje slika"** (1200×760). Loads a VAE `.mat` through `generative/loadVaeModel` (Serbian errors for invalid or non-VAE files). Left: number of images, seed, `Generiši`, interpolation steps, `Interpolacija`, `Latentni manifold` (enabled only when `latentDim == 2`), `Učitaj dataset` + `Rekonstrukcija`, `Sačuvaj grid (PNG)`. Right, in a `uitabgroup`: *Generisanje* (image grid + interpolation row), *Latentni prostor* (manifold over [-3, 3]² + original-vs-reconstruction of random test images) and *Evaluacija klasifikatorom* (load a classifier `.mat`, generate N images, class histogram, mean max-softmax confidence, simplified Inception Score, and a warning when the classifier's `datasetName` differs from the VAE's). |

### Training flow (`TrainingCNN`)

The whole pipeline lives in `cnn_core/` (next section); `TrainingCNN` only reads its controls into
the parameter struct, calls `trainCNNModel` + `saveCNNModel` and shows the result. The experiment
scripts call the same functions.

`[layers, netInputSize, normalization] = getLayers(archName, inputSize, numClasses, normalization)`
(`cnn_core/getLayers.m`) is a `switch` over the two supported architectures, both trained from
scratch at the dataset size:

- `LeNet` (2 conv + 3 FC) and `AlexNet` (CIFAR-scale, 5 conv + 3 FC; the first conv strides for
  inputs larger than 64 px). The normalization choice is mapped onto `imageInputLayer`:
  `MinMax` → `'rescale-zero-one'`, `Mean-Std` → `'zscore'`, `None` → `'none'`.
- Unknown names error (`PhotoLab:unknownArchitecture`). There is no silent fallback CNN.
- **ResNet-18, MobileNet-v2 and SqueezeNet were removed** because they need pretrained-model
  Add-Ons and 224/227 px inputs. Re-adding them would mean a `case` in `getLayers`, a row in
  `CNNArchitectures.getArchitecturesData` and (for transfer learning) a way to load the Add-On net.

Every datastore is wrapped in `augmentedImageDatastore(netInputSize, imds, 'ColorPreprocessing', ...)`,
which reconciles on-disk size and channels with what the net needs. The dataset's size and channels
come from `photolab_dataset.mat` if present. `metrics/evaluateModelOnTestSet` and
`generative/evaluateWithClassifier` rebuild exactly this preprocessing (the master copy is
`cnn_core/buildAugmentedDatastores`) — keep the three in step.

`getTrainingOptions(p, validationData)` (`cnn_core/`) takes the struct from `collectParams` and supports `sgdm`
(Momentum), `adam` (β1, β2, ε) and `rmsprop` (decay, ε). It errors on anything else. Every control
in the window is read: validation split, `ValidationFrequency`, `ValidationPatience` (0 = off),
`GradientThreshold` (0 = off), shuffle, plots, augmentation (flip + translation), and GPU
(`ExecutionEnvironment` `'gpu'`/`'cpu'`; `probeGPU` only enables the checkbox when `canUseGPU()`).

Training expects `training/` and `testing/` subfolders with one subfolder per class (it still
descends one level through a single wrapper folder, using a local variable). `training/` is split with
`splitEachLabel` into train/validation.

**Classifier `.mat` files** (saved by `TrainingCNN`) contain:

| Field | Content |
|---|---|
| `net` | the trained `SeriesNetwork` / `DAGNetwork` |
| `accuracy` | test accuracy in [0, 1] |
| `classNames` | string vector, in the network's class order |
| `inputSize` | `[H W C]` the net was fed |
| `normalization` | `'None'` / `'MinMax'` / `'Mean-Std'` |
| `architecture` | `'LeNet'` / `'AlexNet'` |
| `datasetName` | dataset folder name, e.g. `MNIST_28x28` |
| `yTrue`, `yPred` | categorical labels and predictions on the `testing/` split |
| `testFiles` | cell array of the test image paths, in the same order |

Models saved before `yTrue`/`yPred`/`testFiles` were added lack those three fields;
`EvaluationMetricsApp` handles that by classifying a dataset folder itself.

The legacy Deep Learning API (`trainNetwork`, `classificationLayer`, `SeriesNetwork`/`DAGNetwork`)
is used for the classifier. It is still available in R2025b (flagged "not recommended"). Stay on it
for the CNN half unless you are deliberately migrating the whole file — the VAE is the one exception
(next section).

## Generative models (VAE) — `generative/`

**Exception to the "stay on the legacy API" rule:** the VAE is built with `dlnetwork` and a **custom
training loop** (`dlfeval`, `dlgradient`, `adamupdate`), because `trainNetwork` cannot express a
loss with a sampling step and a KL term. Do not port it to `trainNetwork`, and do not use the
`dlnetwork` style for the classifiers.

**VAE is the only generative architecture the project supports.** There is no second generative
model, no model-type selector in the UI and no code path for one; `loadVaeModel` rejects any file
whose `modelType` is not `'VAE'`. Keep it that way unless a new architecture is added end to end
(functions, both windows, saved-file format, docs).

Design: convolutional encoder → `mu`, `logVar` → reparameterization `z = mu + exp(0.5*logVar) .* ε`
→ transposed-convolution decoder with a sigmoid output in `[0, 1]`. Loss = reconstruction + `β·KL`,
where the reconstruction term is BCE (default for grayscale) or MSE (default for colour), summed
over pixels and averaged over the batch. Supported images: 28×28 and 32×32 with 1 or 3 channels
(MNIST / Fashion-MNIST are 28×28×1, CIFAR-10 is 32×32×3). No pretrained network is used. The
decoder starts from a 1×1×latentDim "image" and a transposed convolution (equivalent to a linear
projection plus reshape), so the saved networks contain only built-in layers. On the reference CPU a
10 000-image MNIST epoch takes about 17 s.

| File | Role |
|---|---|
| `vaeEncoderNetwork.m`, `vaeDecoderNetwork.m` | Build the two `dlnetwork`s (`[H W]`, channels, `latentDim`). |
| `vaeSampleLatent.m` | Reparameterization trick. |
| `vaeReconstructionLoss.m`, `vaeModelLoss.m` | BCE/MSE term and the full loss + gradients (called through `dlfeval`). |
| `vaeDefaultParams.m` | Default training parameters (`reconLossType 'auto'` → BCE for grayscale, MSE for colour). |
| `loadGenerativeDataset.m`, `readVaeImage.m` | Read `training/` into one `single` `H×W×C×N` array in [0, 1]; optional random subsample. Requires `photolab_dataset.mat`. |
| `trainGenerativeModel.m` | `model = trainGenerativeModel(params, datasetPath, progressFcn)`: the whole loop. `progressFcn(info)` gets `info.phase = 'loading'` while reading and `'epoch'` after every epoch (losses, history, uint8 sample grid); a truthy return stops after that epoch. `[]` runs without callbacks. Returns the struct to save with `save(file, '-struct', 'model')`. Restores the caller's RNG. |
| `vaeDecodeLatent.m` | Decode latent vectors to `single` images in chunks. |
| `generateImages.m`, `latentInterpolation.m`, `latentManifold.m`, `reconstructImages.m` | Sampling from `N(0, I)` with a seeded `RandStream`, interpolation between two random latent points, decoding a `[-3, 3]²` grid (latentDim 2 only), and encode→decode of given images with the posterior mean. |
| `sampleGridImage.m` | Tile `uint8` images into one image (`imtile`). |
| `loadVaeModel.m` | Load + validate a VAE `.mat`; Serbian error messages. |
| `evaluateWithClassifier.m` | Generate N images, feed them to a PhotoLab classifier the way training images were fed (uint8, 0–255, `augmentedImageDatastore`; the net's input layer normalizes), return class counts, mean max-softmax confidence and the simplified Inception Score `exp(mean_x KL(p(y|x) ‖ p(y)))`. |

The fixed latent matrix used for the per-epoch sample grid is drawn once from the run's seed before
the loop, so the grids in `sampleGrids` are comparable between epochs. Generation and manifold
helpers use their own `RandStream`, never the global one.

**VAE `.mat` files** (saved by `ImageGeneratingModelTraining` / `trainGenerativeModel`) contain:

| Field | Content |
|---|---|
| `modelType` | `'VAE'` (required by `loadVaeModel`) |
| `encoder`, `decoder` | `dlnetwork`s (required) |
| `latentDim` | latent dimension (required) |
| `imageSize`, `channels` | `[H W]` and 1 or 3, read from the dataset manifest (required) |
| `outputRange` | `'[0,1]'` (required) |
| `datasetName` | e.g. `MNIST_28x28` (required; compared with the classifier's in the evaluation tab) |
| `classNames` | dataset class names |
| `epochs`, `epochsCompleted` | requested / actually run epochs (fewer after `Zaustavi`) |
| `batchSize`, `learnRate`, `seed`, `beta`, `maxImages`, `numSamples` | training parameters |
| `reconLossType` | `'BCE'` or `'MSE'` |
| `lossHistory` | struct with per-epoch vectors `total`, `recon`, `kl` |
| `trainingTime` | seconds |
| `sampleGrids` | `uint8` `H'×W'×C'×epochsCompleted`, the fixed-latent sample grid of every epoch |

## `cnn_core/` — the shared CNN pipeline

Plain functions lifted out of `TrainingCNN`, so the window and the experiment scripts run **exactly
the same code** (a model from the script is "trained in PhotoLab"). Every training parameter travels
in one struct `p` (see `defaultTrainingParams`; the field names are those of
`TrainingCNN.collectParams`). Add the folder to the path (`PhotoLab.mlapp` and `cnn_Menu` do).

| File | Role |
|---|---|
| `trainCNNModel.m` | `result = trainCNNModel(datasetPath, architecture, normalization, p, inputDimensions, progressFcn)`: split, layers, datastores, `trainNetwork`, evaluate on `testing/`. `progressFcn` gets a struct with `phase` (`'training'` / `'evaluating'`) and `message`, or `[]`. Times training and test evaluation separately (`trainingTime`, `testTime`). |
| `saveCNNModel.m` | `saveCNNModel(file, result, extra)`: writes the classifier `.mat` fields documented below; every field of the optional struct `extra` is added (the runner adds `info`). |
| `getLayers.m`, `getInputNormalization.m`, `getTrainingOptions.m` | Architectures (LeNet, AlexNet), normalization mapping, `trainingOptions` for sgdm / adam / rmsprop. |
| `resolveDatasetPath.m`, `loadDatasetSplits.m`, `buildAugmentedDatastores.m` | Wrapper-folder descent, datastores + validation split, `augmentedImageDatastore` wrapping and augmentation. |
| `evaluateOnTestSet.m`, `countLearnables.m` | `classify` on the test split (timed); learnable parameter count. |
| `defaultTrainingParams.m` | The default `p`. |

Three optional `p` fields exist for scripts and are never set by the window: `verbose` (MATLAB's
console training log, default false), `subsetFraction` (< 1 keeps a stratified fraction of both
`training/` and `testing/`; used by the benchmark) and `validationFrequency = 0` (validate once per
epoch; the window's spinner cannot produce 0).

## `experiments/` — thesis experiments

Run from the repo root (any working directory works; the scripts resolve paths from their own
location and add the helper folders themselves). Everything is CPU-only and unattended.

| File | Role |
|---|---|
| `experimentPlan.m` | `plan = experimentPlan(includeCIFAR10, includeCIFAR10Aug)`: the editable plan as a table. Baseline: Adam, LR 1e-3, batch 128, 10 epochs, MinMax, no augmentation, native resolution, validation split 0.1, seed 42; every row overrides only what the plan lists (R01-R15; R16-R17 with `includeCIFAR10`, 20 epochs; R18 also needs `includeCIFAR10Aug`). |
| `runExperiments.m` | Runs the plan (`'IncludeCIFAR10'`, `'IncludeCIFAR10Aug'`, `'Only'`, `'Plan'` options). Downloads missing datasets (`ensureDataset.m`, which calls `prepareX(dir, [], size)`), then per run `rng(seed)`, `trainCNNModel`, `experiments/models/<runId>.mat` (classifier fields + `info`, openable by `ImageClassificationApp` / `EvaluationMetricsApp`) and console log `experiments/logs/<runId>.log`. Appends one row to `experiments/results.csv` right after each run (`runId, experiment, architecture, dataset, inputSize, normalization, optimizer, learnRate, batchSize, epochs, augmentation, seed, finalValAccuracy, bestValAccuracy, testAccuracy, macroF1, trainTimeSec, testTimeSec, numLearnables, modelFile, status, errorMessage, timestamp`; accuracies are fractions in [0, 1]). **Resume:** runIds with status `ok` and an existing model file are skipped; failed runs are logged as `error` and retried on the next call (older error rows stay in the CSV). Experiment runs validate once per epoch with early stopping off, so every row runs its full epoch count. |
| `planRowToParams.m` | One plan row to the `p` struct for `trainCNNModel`. |
| `benchmarkPlan.m` | Trains every distinct (architecture, dataset, size, augmentation) combination for 1 epoch on 5 % and 10 % stratified subsets, fits `time = overhead + epochs x per-epoch` and prints an estimate per run and in total. Run it first to choose what to leave running overnight. |
| `runGenerativeExperiments.m` | VAE runs G01-G04 (MNIST / FashionMNIST x latentDim 2 / 16, 20 epochs, beta 1, 10 000 images) with `trainGenerativeModel`; models in `experiments/generative/`, rows in `experiments/generative_results.csv`. If `experiments/models/R01.mat` / `R02.mat` exist, also mean confidence, class histogram and simplified Inception Score on 1000 generated images. Same resume / log behaviour. |
| `makeFigures.m` | Reads both CSVs and writes the thesis PNGs to `experiments/figures/` (accuracy per architecture x dataset, accuracy vs time, optimizer/LR, normalization, augmentation, resolution, best-model confusion matrix per dataset, VAE losses). Figures whose runs are missing are skipped. |

```matlab
addpath experiments
benchmarkPlan                       % how long will it take?
runExperiments                      % R01-R15; runExperiments('IncludeCIFAR10', true) adds R16-R17
runGenerativeExperiments            % run after R01/R02 so the classifier columns are filled
makeFigures
```

Unattended from a terminal: `matlab -batch "addpath experiments; runExperiments"`. Models, logs,
CSVs and the VAE folder are gitignored; `experiments/figures/` is tracked. Delete
`experiments/results.csv` (and the model) to force a run to be repeated.

## `scripts/` — dataset preparation

The classification datasets use `prepareX(outputDir, h, targetSize)`. `h` is an optional `waitbar`
handle and `targetSize` is `[H W]`, or `[]` for native resolution. They download, extract,
reorganize into `training/` + `testing/` class subfolders, resize, delete the archive, and finally
write the `photolab_dataset.mat` manifest (`imageSize`, `channels`, `classNames`, `datasetName`,
`createdAt`) with `writeDatasetManifest`. The manifest is written last, so its presence means the
download completed. `DatasetManagerApp.downloadDataset` calls them, and on any error does
`rmdir(dir, 's')` to clean up. The manifest is also what the evaluation and generative windows use
to accept a dataset folder.

**Class folder names must sort in label order as strings.** `imageDatastore` sorts folder names
lexically, so use zero-padded prefixes (`%02d_<name>`, `%03d_<name>`). Plain `1..10` sorts as
`1, 10, 2, …` and silently permutes the labels.

| File | Source | Result |
|---|---|---|
| `prepareMNIST.m` | github myleott/mnist_png `.tar.gz` | 28×28×1, folders `0`…`9` (wrapper folder flattened) |
| `prepareFashionMNIST.m` | fashion-mnist S3 idx files | 28×28×1, folders `01_T-shirt` … `10_Ankle-boot` |
| `prepareCIFAR10.m` | cs.toronto.edu cifar-10-matlab | 32×32×3, folders `01_airplane` … `10_truck` |
| `prepareCIFAR100.m` | cs.toronto.edu cifar-100-matlab | 32×32×3, folders `001_<label>` … |
| `resizeImageFolder.m` | — | Helper: `imresize` every PNG under `training/` + `testing/` in place |
| `writeDatasetManifest.m` | — | Helper: writes `photolab_dataset.mat` |
| `preparePTBXL.m` | PhysioNet PTB-XL 1.0.3 | 1-D ECG signals; 20-min `weboptions` timeout (not offered in `DatasetManagerApp`, not used by anything) |
| `convertIdxToImages.m` | — | Helper: idx → per-class PNG folders (`train/`, `test/`) |

## `metrics/` — evaluation

Plain functions over categorical/numeric label vectors, all per-class except accuracy:
`computeAccuracy` (scalar `mean(yTrue == yPred)`), `computePrecision`, `computeRecall`,
`computeF1`. Each derives classes from `unique(yTrue)` and returns a `1×numClasses`
row vector, with 0 substituted for divide-by-zero cases. `computeF1` recomputes precision and
recall internally instead of calling the other two. Two helpers serve `EvaluationMetricsApp`:
`evaluateModelOnTestSet(net, datasetPath)` → `[yTrue, yPred, files]` (classifies a dataset's
`testing/` split with the training preprocessing; errors if the manifest is missing or the classes do
not match the net) and `topConfusions(yTrue, yPred, n)` → table `Stvarna` / `Predviđena` / `Broj`.

## UI design system

`TrainingCNN`, `ImageClassificationApp`, `EvaluationMetricsApp`, `ImageGeneratingModelTraining`,
`ImageGeneratingFromModel`, `DatasetManagerApp`, `CNNArchitectures` and every app in `options_ui/`
follow this system, and the three menus (`PhotoLab`, `Options`, `cnn_Menu`) follow the menu rules
below. New windows should match it. Only `CNNIntroductionApp` predates it. In `options_ui/`,
tool-heavy apps are 1200×760 with a 372 px controls panel at the left and image panels at the right;
simple two-image apps are 900×620.

- **Window size.** Workflow apps (`TrainingCNN`, `ImageClassificationApp`, `EvaluationMetricsApp`, the
  two generative windows): 1200×760. Dialog/selector apps (`DatasetManagerApp`, `CNNArchitectures`):
  900×620. Every window calls `movegui(<figure>, 'center')` in `startupFcn`.
- **Typography.** Window title 22 pt bold (top-left, `[24 H-56 … 32]`). Panel titles 14 pt bold
  (`uipanel` `FontSize`/`FontWeight`). Section labels 13 pt. Controls and labels 12 pt. Metrics and
  readouts 20 pt. Monospace for paths 11 pt `Courier New`.
- **Layout.** 24 px outer margin, 16 px between panels, rows pitched 36 px (24 px control + 12 px gap).
  Standard inputs are 24 px high. Secondary buttons are 36×160 and primary action buttons are 44×200,
  placed bottom-right of their panel or top-right of a dialog.
- **Workflow window with several result views.** When one window has more views than fit at
  1200×760 (`ImageGeneratingFromModel`), keep the 372 px controls panels fixed at the left and put the
  views in a `uitabgroup` on the right (`[412 24 764 660]`), one tab per task. Buttons that act on a
  tab's content may live in the left panel; they switch to the tab that shows their result.
- **Colour.** Primary action: `BackgroundColor [0.20 0.45 0.75]`, white bold text; one per window.
  Success/metric highlight: `[0.18 0.55 0.34]`. Warning text: `[0.85 0.33 0.10]`.
- **Feedback.** Missing input → `uialert(fig, '… prvo!', 'Warning')`. Errors → `uialert(fig, msg, 'Greška')`.
  Long batch work → `uiprogressdlg`, while downloads keep the scripts' `waitbar`. Disable the
  triggering button (or, in `TrainingCNN` and `ImageGeneratingModelTraining`, every input via
  `setBusy`) while work runs.

### Menu windows

Menus (`PhotoLab`, `Options`, `cnn_Menu`) have no workflow of their own; they group buttons that open
other windows. One layout for all three:

- **Size.** A pure navigation menu is 900×620 (`PhotoLab`). A hub menu that also shows state or an
  image preview is 1200×760 (`Options`, `cnn_Menu`). `movegui(fig, 'center')` in `startupFcn`.
- **Header.** Window title 22 pt bold top-left (`[24 704 800 32]`) and one 13 pt `WordWrap`
  description under it (`[24 668 1152 24]`). `PhotoLab` uses a 36 pt bold brand name and a taller
  description instead.
- **Grouping.** Navigation buttons sit in titled `uipanel`s (14 pt bold), 24 px from the window
  edge and 16 px apart. Buttons are 240×48, 12 pt, `WordWrap` on, on a 16 px gutter and a 60 px row
  pitch (`PhotoLab`'s two peer entries are 280×56 at 14 pt).
- **State readouts.** 13 pt label pairs with a 120 px label column and 36 px row pitch, inside the
  panel they describe (`cnn_Menu`: Arhitektura / Dataset / Normalizacija).
- **Colour.** At most one primary button (44×200, `[0.20 0.45 0.75]`, white bold 13 pt): the one that
  starts the window's main workflow (`Options` → "Učitaj sliku", `cnn_Menu` → "Treniranje CNN").
  Menus whose entries are peers have none.
- Restyling a menu must not change callbacks or component names; verify by diffing the callback
  section of `mlapp_src/<Menu>.m`.

## Known rough edges

Be aware of these; don't assume they are intentional, but don't fix them as drive-by changes either.

- **Relative paths depend on `pwd`.** Sample images and `datasets/` resolve against the current
  directory, not the app's location (unlike `PhotoLab.mlapp`, which does use `mfilename('fullpath')`).
  The dataset pickers of the evaluation and generative windows start in `pwd/datasets` for the same
  reason.
- **`+SampleImages` is a MATLAB package folder** (the `+` prefix is reserved by the language) but
  is used as a plain image directory. It also holds leftovers no code uses:
  `imagenet_sample.jpg` and `Results/` (masks written by the removed segmentation app).
- **Old datasets.** Folders downloaded before the refactor (`datasets/MNIST`, `datasets/FashionMNIST`
  with `1..10` folders, …) have no manifest and are not selectable any more. Fashion-MNIST/CIFAR-10
  models trained on them have mis-ordered class names; delete and re-download.
- **Older classifier models lack `yTrue`/`yPred`/`testFiles`.** `EvaluationMetricsApp` reproduces them
  from a dataset folder; `ImageClassificationApp` does not need them.
- **`DatasetManagerApp` still offers a `224x224` resize** although no remaining architecture needs
  it (it was there for the pretrained networks).
- **`PhotoLab.mlapp` calls `savepath`** every time a menu button is pressed, which rewrites the
  user's `pathdef.m`.
- **`ColorFormatsConversion`** always runs `lab2rgb` when saving, whatever conversion is shown, and
  assigns raw `rgb2lab` output to `ImageSource`.
- **`ImageFusion.fuseImages`** is missing a semicolon (`fusedCA = min(cA1, cA2)`) and prints to the console.
- **`scripts/preparePTBXL.m`** is not called by anything.

## Git conventions

Feature branches merged into `main` via PRs, named `feature/<topic>` or `fix/<topic>`
(e.g. `feature/generative-models`, `fix/cleanup`). Commit messages are short and imperative.
`datasets/` is gitignored; do not commit downloaded data or trained `.mat` models (classifier or VAE)
— past commits had to remove MNIST images from history. The same goes for `experiments/models/`,
`experiments/generative/`, `experiments/logs/` and the two experiment CSVs (all gitignored).
