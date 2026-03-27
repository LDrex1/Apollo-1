# Godot JamJar

A batteries-included template for the Godot Engine, designed for game jams.

**Sections:**

1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Project Defaults](#project-defaults)
4. [Provided Systems](#provided-systems)
5. [Demo Project](#demo-project)
6. [License](#license)

## Getting Started

There are a few different ways you can start a new project from this template, depending on whether
you want to use GitHub or another provider.

### GitHub.com

Create a new repository from the template [here](https://github.com/new?template_name=godot-jamjar&template_owner=CreatedBySeb),
then clone your repository locally to start working.

### GitHub CLI

Replace `my-project` with the name of your project, then run the following command to create a
project as a private GitHub repo and clone it into your current directory:

```bash
gh repo create "my-project" --clone --template CreatedBySeb/godot-jamjar --private
```

### Git CLI

Replace the value of `PROJECT_NAME` with the name of your project, then run the following to create
a new local repository based on the template in your current directory:

```bash
export PROJECT_NAME="my-project"
git clone https://github.com/CreatedBySeb/godot-jamjar.git --depth 1 "$PROJECT_NAME"
cd "$PROJECT_NAME"
rm -rf .git
git init
git add .
git commit -m "New Godot JamJar project"
```

***Note:** You still need to create a remote Git repository and push your local repository to it if
you want to collaborate on your project or back it up remotely.*

## Project Structure

- `build/web/` - Where the default Web export will be placed, see [Project Defaults](#project-defaults)
- `demo/` - A small Asteroids sample, see [Demo Project](#demo-project)
- `systems/` - The common game systems the template includes for you out-of-box
- `default_bus_layout.tres` - The template's audio bus layout, see [`AudioSystem`](#audiosystem)
- `project.godot` - Project-specific Godot settings, see [Project Defaults](#project-defaults)

## Project Defaults

This template configures a few project settings differently from the Godot defaults for a better
jamming/prototyping experience.

- A window size of 1920x1080 (1080p), with borderless windows enabled
- Scaling enabled for canvas items (2D elements)
- An audio bus with 'BGM' (Background Music) and 'SFX' (Sound Effects) channels to make it easier to
  balance (see also [`AudioSystem`](#audiosystem))
- Additional GDScript warnings:
  - Untyped Declarations: Static types help with avoiding bugs, but also yield performance
    improvements in Godot, so this helps you take advantage of this
  - Unsafe Access: These helps avoid assuming a node will be a type other than what it is guaranteed
    to be, which can lead to difficult to find bugs
- A Web export preset configured to build to `build/web/index.html`, so that the `web` directory is
  ready to be zipped and uploaded to a site like Itch.io or used by GitHub Actions

## Provided Systems

These are some common game systems that most games will need, so they have been added to the
template to enable you to spend more time on your unique logic. Any system marked with
**\[Autoload]** is provided as an autoload, so is always accessible as a singleton by its name.

### `MainMenu`

A basic main menu is provided in `main_menu.tscn` and set as the entrypoint for the project. It has
a basic layout that is easy to tweak, built on top of a theme assigned to the root node. It has a
play button, which loads the configured `game_scene`, a help button, which toggles a pop up with
instructions, a quit button (on supported platforms), which quits the game, and a mute toggle at the
bottom right. It also has a space for credits at the bottom left.

### `AudioSystem`

**\[Autoload]**

This system provides some convenience methods for working with continuous sounds and for adding
pitch variation to sounds (which helps make them less repetitive).

It uses one `AudioStreamPlayer` node for the BGM (though it can be easily adapted to add more),
which is exposed via the `bgm` property. For sound effects, any `AudioStreamPlayer` node that is a
direct child of the `SFX` node will be auto-registered into its `sfx` dictionary property, and can
be used with the convenience methods. You can configure multiple tracks for the BGM, and specify a
default one to play when the game starts, which you can then switch between using the relevant
methods. There is also a `mute` method for globally enabling or disabling playback.

During development, an error will be raised if an `AudioStreamPlayer` in the `AudioSystem` has an
incorrect bus, which could lead to incorrect mixing.

### `SaveSystem`

**\[Autoload]**

This system provides some cross-platform methods for reading and persisting data, such as for
configuring settings, saving high scores and recording progress. By default it treats unexpected
data as if there was nothing there and overwrites it, but you may want to replace this logic if you
update the save format in the future. It currently doesn't support native objects (e.g. resources),
but could be modified to do so.

### `SceneSystem`

**\[Autoload]**

This system provides methods for loading resources (including scenes) in the background to avoid
interrupting gameplay, and for transitioning to a new scene then performing actions afterwards. The
main idea is that you can load in a new scene using `bg_load`, which will return a `PackedScene`,
then you can instantiate this, do any configuration required and then call `transition` with it. You
could also use `bg_load` for streaming in level chunks, enemies, assets or anything else you may
need soon but don't want to block the main thread for.

## Demo Project

This repository contains a demo project, which is a version of Asteroids, used for development and
to showcase some of the systems provided by the template. It is largely self-contained to the
`demo/` folder, but some of the systems have had values set or assets added for the demo project.
These are safe to leave in place, or can be removed. Note that if you remove the `demo/` folder,
then you will need to ensure you remove any demo assets from the systems or you may encounter
errors.

Below is a list of affected systems:

- `AudioSystem`: Contains a BGM track and sound effects. To clean up, delete all the nodes under
  SFX, then click the 'BGM' node and click the circular arrow next to 'Stream'

## License

Most of this template is provided under the MIT License, though some of the included assets are
subject to other licenses from their original creators.

- `logo.svg`: [Godot Logo](https://godotengine.org/press/) by Andrea Calabró, licensed under CC-BY
  4.0
- `demo/bgm.ogg`: ['Background space track'](https://opengameart.org/content/background-space-track)
  by yd, licensed under CC0
- `demo/asteroid.png`, `demo/laser.png`, `demo/ship.png`: ['Simple Space'](https://kenney.nl/assets/simple-space)
  by Kenney, licensed under CC0
- `demo/explosion.ogg`, `demo/laser.ogg`, `demo/thruster.ogg`: ['Sci-fi Sounds'](https://kenney.nl/assets/sci-fi-sounds)
  by Kenney, licensed under CC0

Filenames don't necessarily match with their sources. All other files are original and licensed
under the MIT License.
