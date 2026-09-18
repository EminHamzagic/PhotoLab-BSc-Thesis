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
  MATLAB path (see `README.md`) — `Filters.mlapp` calls `BM3D(...)` directly.
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
├── scripts/                  Dataset download + preparation functions (plain .m).
├── metrics/                  Classification metric functions (plain .m).
├── utils/                    Misc helpers (currently one empty stub).
├── +SampleImages/            Thumbnail images shown in the dataset browser.
├── resources/appDesigner.json  App Designer custom-component metadata (auto-generated).
├── lgraphUNet.mat            Saved U-Net layerGraph, loadable by the segmentation app.
├── lgraphSegNet.mat          Saved SegNet layerGraph, loadable by the segmentation app.
├── predictions.mat           Sample saved predictions (`yPred`) for the metrics app.
└── datasets/                 NOT in git (.gitignore). Created at runtime by the dataset app.
```

## App architecture

Everything is a `matlab.apps.AppBase` subclass in App Designer format. `.mlapp` files are ZIP
archives; the MATLAB code lives in `matlab/document.xml` inside them as a CDATA block. **You
cannot meaningfully edit a `.mlapp` with a text editor** — it must be opened in App Designer.
To *read* the code of an app, unzip it and extract the CDATA sections (note the source stores
newlines as literal `\n` escapes).

Two parent→child patterns are used, and they are inconsistent — match whichever one the file
you are editing already uses:

1. **`loadImage` push** (all of `options_ui/`): `Options` reads an image once into
   `app.ImageFile`, then does `child = ChildApp(); child.loadImage(app.ImageFile);`. Child apps
   expose a public `loadImage(app, image)` method and store it in `app.LoadedImage`.
   `ImageFusion` is the exception — it loads its own two images.
2. **`ParentApp` + `uiwait`/`uiresume`** (`cnn_Menu` → `CNNArchitectures`, `DatasetManagerApp`):
   the child gets a `ParentApp` reference and a public result property (`choosenArch`,
   `choosenDataset`, `setDimensions`); the parent blocks on `uiwait(child.UIFigure)`, reads the
   property, then `delete(child)`.

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
| `Filters.mlapp` | Adds salt & pepper / Gaussian noise via slider, then denoises: median (`medfilt2` per channel), Gaussian (`imgaussfilt`), a hand-written block-matching loop (16×16 blocks, ±8 search), and BM3D (external lib, per channel). |
| `WienerFilter.mlapp` | Converts to grayscale, then `wiener2`. |
| `ActiveContours.mlapp` | Builds a Rectangle or Ellipse mask, shows it as a red alpha overlay, then runs `activecontour(..., 'Chan-Vese')` with slider-controlled iterations and SmoothFactor. |
| `HarrisCornerDetectionFeature.mlapp` | Harris response computed by hand (gradients → `imgaussfilt` on Ix², Iy², IxIy) with a threshold slider. |
| `ImageFusion.mlapp` | Loads two images itself, resizes to the common minimum, then per channel: `dwt2` (haar) → min of approximation coeffs, max of detail coeffs → `idwt2`. Can save the fused image. |

## `cnn_ui/` — deep learning

| File | What it does |
|---|---|
| `CNNIntroductionApp.mlapp` | Static explanatory text + MathWorks hyperlinks. No logic. |
| `CNNArchitectures.mlapp` | Table of 11 architectures (LeNet … YOLOv4). Selecting a row fills a details pane and sets `choosenArch`. Only the name string is returned. |
| `DatasetManagerApp.mlapp` | Dataset dropdown, stats text, sample image, class-distribution bar chart, resize/normalization preview dropdowns, and the Download button. Returns `choosenDataset` (a path) and `setDimensions`. |
| `TrainingCNN.mlapp` | Receives `(architecture, dataset, dimensions)` via `loadData`, builds layers, trains, evaluates, saves. |
| `ImageClassificationApp.mlapp` | Load a `.mat` model + one image or a folder; `classify`; shows top-1 and top-5. |
| `SemanticSegmentationApp.mlapp` | Load `lgraphUNet.mat`/`lgraphSegNet.mat` (or fall back to a random-weight dummy net), run `semanticseg`, overlay with `labeloverlay`, write masks to a `Results/` subfolder next to the input images. |
| `EvaluationMetricsApp.mlapp` | Load `yTrue`/`yPred` from `.mat` or `.csv`, compute the `metrics/` functions, draw a confusion matrix (`imagesc`) and a per-class Precision/Recall/F1 bar chart. |

### Training flow (`TrainingCNN`)

`getLayers(archName, inputSize, numClasses)` is a `switch` that returns a layer array:
`LeNet` and `AlexNet` are defined inline, `VGG-16` and `ResNet` pull pretrained `vgg16`/`resnet50`
and swap the final FC + classification layers, everything else falls through to a small fallback
CNN. Architectures listed in `CNNArchitectures` but not handled here silently get the fallback.

`getTrainingOptions` supports `sgdm`, `adam`, `rmsprop` and errors on anything else.

Training expects the dataset folder to contain `training/` and `testing/` subfolders with one
subfolder per class; it auto-descends one level if the path contains a single wrapper directory.
It uses `imageDatastore` + `trainNetwork`, then `classify` on the test set, and `save(savePath,
'net', 'accuracy')`.

Note this uses the **legacy** Deep Learning API (`trainNetwork`, `classificationLayer`,
`SeriesNetwork`/`DAGNetwork`), not `trainnet`/`dlnetwork`. Stay on the legacy API unless you are
deliberately migrating the whole file.

## `scripts/` — dataset preparation

All are `prepareX(outputDir, h)` where `h` is an optional `waitbar` handle. They download,
extract, and reorganize into `training/` + `testing/` class subfolders, then delete the archive.
`DatasetManagerApp.downloadDataset` calls them, and on any error does `rmdir(dir, 's')` to clean up.

| File | Source | Result |
|---|---|---|
| `prepareFashionMNIST.m` | fashion-mnist S3 idx files | 28×28×1 |
| `prepareCIFAR10.m` | cs.toronto.edu cifar-10-matlab | 32×32×3, folders named `<n>_<label>` |
| `prepareCIFAR100.m` | cs.toronto.edu cifar-100-matlab | 32×32×3 |
| `prepareStreetScene.m` | Zenodo record 10870472 | 128×128×3, for segmentation |
| `preparePTBXL.m` | PhysioNet PTB-XL 1.0.3 | 1-D ECG signals; 20-min `weboptions` timeout |
| `convertIdxToImages.m` | — | Helper: idx → per-class PNG folders (`train/`, `test/`) |

MNIST is the odd one out: `DatasetManagerApp` handles it inline with `websave` + `untar` of
`mnist_png.tar.gz` rather than through a `scripts/` function.

## `metrics/` — evaluation

Plain functions over categorical/numeric label vectors, all per-class except accuracy:
`computeAccuracy` (scalar `mean(yTrue == yPred)`), `computePrecision`, `computeRecall`,
`computeF1`, `computeIoU`. Each derives classes from `unique(yTrue)` and returns a `1×numClasses`
row vector, with 0 substituted for divide-by-zero cases. `computeF1` recomputes precision and
recall internally instead of calling the other two.

## Known rough edges

Be aware of these; don't assume they are intentional, but don't fix them as drive-by changes either.

- **Windows-only paths.** `DatasetManagerApp.displaySampleImage` uses backslashes
  (`imread('+SampleImages\mnist_sample.png')`) — this fails on macOS/Linux and is swallowed by a
  `catch` that shows "Nema dostupnih slika". Use `fullfile` if you touch it.
- **Relative paths depend on `pwd`.** Sample images and `datasets/` resolve against the current
  directory, not the app's location (unlike `PhotoLab.mlapp`, which does use `mfilename('fullpath')`).
- **`+SampleImages` is a MATLAB package folder** (the `+` prefix is reserved by the language) but
  is used as a plain image directory.
- **Class distributions in `DatasetManagerApp` are `rand()` placeholders**, not real counts.
- **`ImageClassificationApp` special-cases Fashion-MNIST** by sniffing for "fashion" in the model
  filename and applying a hardcoded class-name list with an off-by-one shim.
- **`EvaluationMetricsApp` falls back to `cifarModel.mat`** — a file that is not in the repo — and
  then to random data if no predictions are loaded.
- **`SemanticSegmentationApp` silently substitutes a random-weight dummy network** when no valid
  model is selected, so "it runs but the output is noise" is an expected failure mode.
- `utils/segmentationMetrics.m` is an unimplemented App Designer stub (returns its inputs).

## Git conventions

Feature branches merged into `main` via PRs, named `feature/<topic>` or `fix/<topic>`
(e.g. `feature/segmentation`, `fix/cleanup`). Commit messages are short and imperative.
`datasets/` is gitignored; do not commit downloaded data or trained `.mat` models — past commits
had to remove MNIST images from history.
