#!/usr/bin/env bash

echo "Starting setup..."



echo "Installing homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/gre/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Update homebrew recipes
brew update
brew upgrade

# insall xcode commands
xcode-select —-install           

# install oh-my-zsh
$ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

PACKAGES=(
    mas
)

# echo "Installing packages..."
brew install ${PACKAGES[@]}

echo "Cleaning up..."
brew cleanup

echo "Install rosetta 2"
softwareupdate --install-rosetta --agree-to-license

echo "Installing cask..."
brew tap homebrew/cask

CASKS=(
    spotify
    visual-studio-code
    gimp
    whatsapp
    finicky
    adobe-acrobat-reader
    deepl
    setapp
    wow
    ubersicht
    microsoft-edge
    microsoft-office-businesspro
)
# further casks:
# logitech-presentation, parallels-toolbox

echo "Installing cask apps..."
brew install --appdir=/Applications --cask --no-quarantine ${CASKS[@]}

echo "Installing cask fonts..."
brew tap homebrew/cask-fonts

FONTS=(
    font-lato
)

brew install --cask ${FONTS[@]}

echo "Installing cask drivers"
brew tap homebrew/cask-drivers

DRIVERS=(
    sonos
)
# further drivers:
# logitech-options
brew install  --appdir=/Applications --cask --no-quarantine ${DRIVERS[@]}

MAS=(
    442160987
    441258766
    1552826194
    1153157709
)
# 442160987 # FlyCut (1.9.6)
# 975937182 # Fantastical (3.6.4)
# 441258766 # Magnet (2.8.0)
# 1552826194 # MyWallpaper (1.1.2)
# 1153157709 # Speedtest (1.27)

mas install ${MAS[@]}

echo "Setup complete"