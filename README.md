# Surfacer and Scaffolder demo

> _**[Live demo](https://snoringcat.games/play/squirrel-away)**_

This point-and-click platformer game showcases procedural pathfinding using the [Surfacer](https://github.com/SnoringCatGames/surfacer/) framework.

In this game, the user can click anywhere in the level, and the cat character will then jump, walk, and climb across platforms in order to reach that target destination.

> **NOTE:** The [Squirrel Away](https://github.com/SnoringCatGames/squirrel_away) example game is set up as an "**addon**." This means that it cannot run by itself, and must be run within the `addons/` directory of a separate project (that is, this project). This makes Squirrel Away a little more convoluted to run and understand on its own. But this makes it easy to also update Squirrel Away source code when making framework changes from another project. This is important for keeping Squirrel Away up-to-date!

## ⚙️ Getting set up

> **NOTE:** This repo uses [Git submodules](https://git-scm.com/book/en/v2/Git-Tools-Submodules) to include frameworks.

To learn more about how the code works, checkout the [Surfacer](https://github.com/SnoringCatGames/surfacer/) and [Scaffolder](https://github.com/SnoringCatGames/scaffolder/) READMEs.

## 💿 Software used

-   [Surfacer](https://github.com/SnoringCatGames/surfacer/): A framework that enables procedural path-finding across 2D platforms.
-   [Scaffolder](https://github.com/SnoringCatGames/scaffolder/): A framework that provides some general app infrastructure.
-   [Godot](https://godotengine.org/): Game engine.
-   [Piskel](https://www.piskelapp.com/user/5663844106502144): Pixel-art image editor.
-   [Aseprite](https://www.aseprite.org/): Pixel-art image editor.
-   [Bfxr](https://www.bfxr.net/): Sound effects editor.
-   [DefleMask](https://deflemask.com/): Chiptune music tracker.

## 📃 Licenses

-   All code is published under the [MIT license](LICENSE).
-   All art assets (files under `assets/images/`, `assets/music/`, and `assets/sounds/`) are published under the [CC0 1.0 Universal license](https://creativecommons.org/publicdomain/zero/1.0/deed.en).
-   This project depends on various pieces of third-party code that are licensed separately. Here are lists of these third-party licenses:
    -   [addons/scaffolder/src/config/scaffolder_third_party_licenses.gd](https://github.com/SnoringCatGames/scaffolder/blob/master/src/config/scaffolder_third_party_licenses.gd)
    -   [addons/surfacer/src/global/surfacer_third_party_licenses.gd](https://github.com/SnoringCatGames/surfacer/blob/master/src/global/surfacer_third_party_licenses.gd)
    -   [addons/surface_tiler/src/global/surface_tiler_third_party_licenses.gd](https://github.com/SnoringCatGames/surface_tiler/blob/master/src/global/surface_tiler_third_party_licenses.gd)
    -   [addons/squirrel_away/src/config/squirrel_away_third_party_licenses.gd](https://github.com/SnoringCatGames/squirrel_away/blob/master/src/config/squirrel_away_third_party_licenses.gd)

<p align="center">
  <img src="https://github.com/SnoringCatGames/squirrel_away/blob/master/assets/images/loading.gif"
       alt="An animated GIF showing a squirrel running">
</p>
