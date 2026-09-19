# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this project is

PhotoLab is a **MATLAB App Designer** desktop application for image processing and CNN-based
image analysis, built as a university (Fakultet) project. It is a collection of `.mlapp` GUI
apps plus plain `.m` helper functions — there is no build system, no package manager, and no
test suite. Everything runs inside MATLAB.

- **Target MATLAB release:** R2023b (see `resources/appDesigner.json`)
- **Required toolboxes:** Image Processing Toolbox; Deep Learning Toolbox (for the CNN half);
  Wavelet Toolbox (`dwt2`/`idwt2`, used by image fusion); optionally Parallel Computing / GPU.
- **External dependency:** the BM3D library must be downloaded separately and added to the
  MATLAB path (see `README.md`) — `utils/bm3dDenoise.m` wraps it, and `utils/ensureBM3D.m` finds the
  folder and runs `addpath` + `savepath`. It is the **legacy** release:
  `[PSNR, y_est] = BM3D(y, z, sigma, profile, print_to_screen)` (`y` = clean reference, `1` if none;
  grayscale only; `CBM3D` for RGB) with `sigma` on the **0–255** scale, not 0–1.
- **UI language:** Serbian/Bosnian (Latin script). Component names are derived from Serbian
  labels with diacritics stripped, which is why identifiers look mangled
  (`UitajslikuButton` = "Učitaj sliku", `DodavanjeumairazliitifilteriButton` =
  "Dodavanje šuma i različiti filteri"). Keep new UI strings in the same language.
  Code comments are a mix of Serbian and English.

## Running it

Open MATLAB in the repo root and launch `PhotoLab.mlapp`. Both buttons on the main screen call
`addpath` on `cnn_ui`, `options_ui`, `scripts`, `metrics`, `utils` and then `savepath`, so the
helper folders only become visible after the app has been opened once. If you call helper
functions directly from the MATLAB console, add those paths yourself.

There is no CLI entry point and no way to run this headlessly — anything that needs verification
has to be run by the user inside MATLAB.

## Directory layout

```
PhotoLab/
├── PhotoLab.mlapp            Main entry window. Two buttons: image processing / deep learning.
├── Options.mlapp             Image-processing hub. Loads ONE image, hands it to child apps.
├── cnn_Menu.mlapp            Deep-learning hub. Holds selected architecture + dataset state.
├── options_ui/               Child apps for classic image-processing operations.
├── cnn_ui/                   Child apps for the CNN/deep-learning workflow.
├── mlapp_src/                Readable copies of the code embedded in the CNN and options_ui .mlapp files.
├── tools/                    Dev tooling: mlappFromSource.m rebuilds an .mlapp from mlapp_src/;
│                             makeFilterDemoImages.m regenerates the two denoising demo PNGs.
├── scripts/                  Dataset download + preparation functions (plain .m).
├── metrics/                  Classification metric functions (plain .m).
├── utils/                    Denoising helpers (blockMatchingDenoise, bm3dDenoise, ensureBM3D,
│                             addGaussianNoise, estimateNoiseSigma) + one empty stub.
├── +SampleImages/            Thumbnail images shown in the dataset browser.
├── resources/appDesigner.json  App Designer custom-component metadata (auto-generated).
├── lgraphUNet.mat            Saved U-Net layerGraph, loadable by the segmentation app.
├── lgraphSegNet.mat          Saved SegNet layerGraph, loadable by the segmentation app.
├── predictions.mat           Sample saved predictions (`yPred`) for the metrics app.
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

**Editing without App Designer.** The five CNN apps (`cnn_Menu`, `DatasetManagerApp`,
`CNNArchitectures`, `TrainingCNN`, `ImageClassificationApp`) and the ten `options_ui/` apps have
readable copies in `mlapp_src/<App>.m` (`Options` and `PhotoLab` do not). To change one outside App Designer, edit `mlapp_src/<App>.m` and rebuild the
whole `.mlapp` (design model + code) with `tools/mlappFromSource.m`:

```matlab
addpath tools
mlappFromSource('mlapp_src/TrainingCNN.m', 'cnn_ui/TrainingCNN.mlapp')
mlappFromSource('mlapp_src/Filters.m', 'options_ui/Filters.mlapp')
```

Anything that is not a plain `app.X = ...;` statement (e.g. `title(app.UIAxes, ...)`) belongs in
`startupFcn`, not `createComponents`. Long algorithm code belongs in `utils/`, not in a callback.

It parses the App Designer layout (component properties block, editable sections, callbacks,
`startupFcn`, `createComponents`) and saves with App Designer's own
`appdesigner.internal.serialization.MLAPPSerializer`. It keeps the app's metadata/uuid. It only
understands App Designer-generated structure: `createComponents` must contain only `app.X = ...` /
`app.X.Prop = ...` statements (no local variables), and callbacks must be one-level
`function Name(app, event)` methods. It uses internal (undocumented) MATLAB APIs verified on R2023b.

If an app is edited in App Designer instead, copy its code back into `mlapp_src/<App>.m` so the two
stay in sync. Never put `mlapp_src/` or `tools/` output on the MATLAB path next to the apps:
`mlapp_src` classdefs have the same names as the `.mlapp` apps.

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

A third, looser mechanism is used for the remaining CNN apps: state is stuffed into
`app.UIFigure.UserData` (e.g. `SelectedModel`, `TestImageFiles`, `SegmentationModel`, `Images`,
`yTrue`, `yPred`). If you add state to `ImageClassificationApp`, `SemanticSegmentationApp` or
`EvaluationMetricsApp`, keep using `UserData` rather than introducing new properties.

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
| `CNNIntroductionApp.mlapp` | Static explanatory text + MathWorks hyperlinks. No logic. |
| `CNNArchitectures.mlapp` | Table of 5 architectures (LeNet, AlexNet, ResNet-18, MobileNet-v2, SqueezeNet) built from a struct array (`getArchitecturesData`). Selecting any cell in a row sets `choosenArch` from column 1. Only the name string is returned; it must match a `case` in `TrainingCNN.getLayers`. |
| `DatasetManagerApp.mlapp` | MNIST / Fashion-MNIST / CIFAR-10 / CIFAR-100. Resize dropdown (`WxH` entries parsed with `sscanf`; `Custom` adds a new `WxH` entry), normalization dropdown (`None`/`MinMax`/`Mean-Std`), preview, real class counts (`countEachLabel`) once downloaded. One download path driven by `getDatasetConfig`. Returns `choosenDataset` (path to `datasets/<Name>_<W>x<H>`), `setDimensions` (`[H W C]`) and `setNormalization`. |
| `TrainingCNN.mlapp` | Receives `(architecture, dataset, dimensions, normalization)` via `loadData`, builds layers, trains with a validation split, evaluates on `testing/`, saves. Optional GPU. |
| `ImageClassificationApp.mlapp` | Load a `.mat` model (finds `net` or any `SeriesNetwork`/`DAGNetwork`), one image or a folder (`imageDatastore`), classify everything in one `classify` call. Results `uitable`; selecting a row shows the image and a top-5 table. Class names come from the saved `classNames` / the output layer. |
| `SemanticSegmentationApp.mlapp` | Load `lgraphUNet.mat`/`lgraphSegNet.mat` (or fall back to a random-weight dummy net), run `semanticseg`, overlay with `labeloverlay`, write masks to a `Results/` subfolder next to the input images. |
| `EvaluationMetricsApp.mlapp` | Load `yTrue`/`yPred` from `.mat` or `.csv`, compute the `metrics/` functions, draw a confusion matrix (`imagesc`) and a per-class Precision/Recall/F1 bar chart. |

### Training flow (`TrainingCNN`)

`[layers, netInputSize, normalization] = getLayers(archName, inputSize, numClasses, normalization)`
is a `switch`:

- `LeNet` and `AlexNet` (CIFAR-scale, 5 conv + 3 FC) are built from scratch at the dataset size. The
  first AlexNet conv strides for inputs larger than 64 px. The normalization choice is mapped onto
  `imageInputLayer`: `MinMax` → `'rescale-zero-one'`, `Mean-Std` → `'zscore'`, `None` → `'none'`.
- `ResNet-18`, `MobileNet-v2` and `SqueezeNet` load the pretrained net (`loadPretrained` raises a
  `PhotoLab:missingAddon` error that names the Add-On) and replace the last learnable layer
  (`fc1000` / `Logits` / `conv10`) and the classification layer. They keep their ImageNet input
  normalization and report `'ImageNet'`.
- Unknown names error. There is no silent fallback CNN.

Every datastore is wrapped in `augmentedImageDatastore(netInputSize, imds, 'ColorPreprocessing', ...)`,
which reconciles on-disk size and channels with what the net needs (e.g. 28×28×1 MNIST → 224×224×3).
The dataset's size and channels come from `photolab_dataset.mat` if present.

`getTrainingOptions(p, validationData)` takes the struct from `collectParams` and supports `sgdm`
(Momentum), `adam` (β1, β2, ε) and `rmsprop` (decay, ε). It errors on anything else. Every control
in the window is read: validation split, `ValidationFrequency`, `ValidationPatience` (0 = off),
`GradientThreshold` (0 = off), shuffle, plots, augmentation (flip + translation), and GPU
(`ExecutionEnvironment` `'gpu'`/`'cpu'`; `probeGPU` only enables the checkbox when `canUseGPU()`).

Training expects `training/` and `testing/` subfolders with one subfolder per class (it still
descends one level through a single wrapper folder, using a local variable). `training/` is split with
`splitEachLabel` into train/validation. The model is saved as
`save(savePath, 'net', 'accuracy', 'classNames', 'inputSize', 'normalization', 'architecture', 'datasetName')`.

Note this uses the **legacy** Deep Learning API (`trainNetwork`, `classificationLayer`,
`SeriesNetwork`/`DAGNetwork`), not `trainnet`/`dlnetwork`. Stay on the legacy API unless you are
deliberately migrating the whole file.

## `scripts/` — dataset preparation

The classification datasets use `prepareX(outputDir, h, targetSize)`. `h` is an optional `waitbar`
handle and `targetSize` is `[H W]`, or `[]` for native resolution. They download, extract,
reorganize into `training/` + `testing/` class subfolders, resize, delete the archive, and finally
write the `photolab_dataset.mat` manifest (`imageSize`, `channels`, `classNames`, `datasetName`,
`createdAt`) with `writeDatasetManifest`. The manifest is written last, so its presence means the
download completed. `DatasetManagerApp.downloadDataset` calls them, and on any error does
`rmdir(dir, 's')` to clean up.

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
| `prepareStreetScene.m` | Zenodo record 10870472 | 128×128×3, for segmentation (not offered in `DatasetManagerApp`) |
| `preparePTBXL.m` | PhysioNet PTB-XL 1.0.3 | 1-D ECG signals; 20-min `weboptions` timeout (not offered in `DatasetManagerApp`) |
| `convertIdxToImages.m` | — | Helper: idx → per-class PNG folders (`train/`, `test/`) |

## `metrics/` — evaluation

Plain functions over categorical/numeric label vectors, all per-class except accuracy:
`computeAccuracy` (scalar `mean(yTrue == yPred)`), `computePrecision`, `computeRecall`,
`computeF1`, `computeIoU`. Each derives classes from `unique(yTrue)` and returns a `1×numClasses`
row vector, with 0 substituted for divide-by-zero cases. `computeF1` recomputes precision and
recall internally instead of calling the other two.

## UI design system

`TrainingCNN`, `ImageClassificationApp`, `DatasetManagerApp`, `CNNArchitectures` and every app in
`options_ui/` follow this system. New windows should match it. Only the menus (`PhotoLab`, `Options`,
`cnn_Menu`, `CNNIntroductionApp`) predate it. In `options_ui/`, tool-heavy apps are 1200×760 with a
372 px controls panel at the left and image panels at the right; simple two-image apps are 900×620.

- **Window size.** Workflow apps (`TrainingCNN`, `ImageClassificationApp`): 1200×760. Dialog/selector
  apps (`DatasetManagerApp`, `CNNArchitectures`): 900×620. Every window calls
  `movegui(<figure>, 'center')` in `startupFcn`.
- **Typography.** Window title 22 pt bold (top-left, `[24 H-56 … 32]`). Panel titles 14 pt bold
  (`uipanel` `FontSize`/`FontWeight`). Section labels 13 pt. Controls and labels 12 pt. Metrics and
  readouts 20 pt. Monospace for paths 11 pt `Courier New`.
- **Layout.** 24 px outer margin, 16 px between panels, rows pitched 36 px (24 px control + 12 px gap).
  Standard inputs are 24 px high. Secondary buttons are 36×160 and primary action buttons are 44×200,
  placed bottom-right of their panel or top-right of a dialog.
- **Colour.** Primary action: `BackgroundColor [0.20 0.45 0.75]`, white bold text; one per window.
  Success/metric highlight: `[0.18 0.55 0.34]`.
- **Feedback.** Missing input → `uialert(fig, '… prvo!', 'Warning')`. Errors → `uialert(fig, msg, 'Greška')`.
  Long batch work → `uiprogressdlg`, while downloads keep the scripts' `waitbar`. Disable the
  triggering button (or, in `TrainingCNN`, every input via `setBusy`) while work runs.

## Known rough edges

Be aware of these; don't assume they are intentional, but don't fix them as drive-by changes either.

- **Relative paths depend on `pwd`.** Sample images and `datasets/` resolve against the current
  directory, not the app's location (unlike `PhotoLab.mlapp`, which does use `mfilename('fullpath')`).
- **`+SampleImages` is a MATLAB package folder** (the `+` prefix is reserved by the language) but
  is used as a plain image directory.
- **Old datasets.** Folders downloaded before the refactor (`datasets/MNIST`, `datasets/FashionMNIST`
  with `1..10` folders, …) have no manifest and are not selectable any more. Fashion-MNIST/CIFAR-10
  models trained on them have mis-ordered class names; delete and re-download.
- **`EvaluationMetricsApp` falls back to `cifarModel.mat`** — a file that is not in the repo — and
  then to random data if no predictions are loaded.
- **`SemanticSegmentationApp` silently substitutes a random-weight dummy network** when no valid
  model is selected, so "it runs but the output is noise" is an expected failure mode.
- `utils/segmentationMetrics.m` is an unimplemented App Designer stub (returns its inputs).
- **`ColorFormatsConversion`** always runs `lab2rgb` when saving, whatever conversion is shown, and
  assigns raw `rgb2lab` output to `ImageSource`.
- **`ImageFusion.fuseImages`** is missing a semicolon (`fusedCA = min(cA1, cA2)`) and prints to the console.
- **`Options.mlapp` has no `mlapp_src` copy**, so it can only be edited in App Designer.

## Git conventions

Feature branches merged into `main` via PRs, named `feature/<topic>` or `fix/<topic>`
(e.g. `feature/segmentation`, `fix/cleanup`). Commit messages are short and imperative.
`datasets/` is gitignored; do not commit downloaded data or trained `.mat` models — past commits
had to remove MNIST images from history.
