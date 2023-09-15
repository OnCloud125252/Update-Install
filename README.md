# UpdateInstall

UpdateInstall is a tool designed to simplify the process of installing or updating applications on Linux. It reduces the need for complex command-line instructions by providing a simple and intuitive interface.

## Features

- Install or update applications with just one command.
- Automatically handles the app installation and update process.
- Full control over the source of the app and customizable commands.
- Efficient download behavior with automatic caching.
- Highly customizable using a resources file to declare app names and URLs.

## Installation

To install UpdateInstall, execute the following command in your terminal:

```bash
wget -qO- https://short.on-cloud.tw/UpdateInstall | bash
```

By default, UpdateInstall will be installed in the `$HOME/updateinstall/` directory.

## Usage

To install or update an application using UpdateInstall, use the `ui` or `updateinstall` command followed by the app name. Here are some examples:

- Updating UpdateInstall:
  
  ```bash
  ui update
  ```

- Installing Vencord:
  
  ```bash
  ui vencord
  ```

- Installing or updating Discord:
  
  ```bash
  ui discord
  ```

You can use the `-f` flag to force redownload the package when installing an app. For example:

```bash
ui discord -f
```

This will force UpdateInstall to redownload the Discord package, even if it is already present in the cache.

> [!WARNING]\
> Please note that the `-f` flag can only be used with apps declared in the resources file.

## Default Commands

UpdateInstall provides several built-in commands:

- `ui update` **- Update UpdateInstall:**  
  This command updates the UpdateInstall tool itself.

- `ui updateresources` **- Update Resources File:**  
  Use this command to update the resources file.
  ***Please note that running this command will replace the current resources file with an updated version.***

- `ui updateall` **- Update All Apps:**  
  This command updates all the apps listed in the resources file.

- `ui vencord` **- Install Vencord:**  
  Use this command to install Vencord. Note that you may need to reinstall Vencord after updating Discord.

> [!INFO]\
> Yes, UpdateInstall have Vencord installer built-in because:
> \1. The original Discord sucks :<
> \2. Why not?

## Resources File

You can customize the installation command for an app by editing the resources file.  
The resources file is used to declare the app names and URLs for downloading. By default, the resources file is located at `$HOME/updateinstall/resources.txt`.  

You can add or modify resources by editing this file. Here's an example of a resources file:

```txt
discord=https://discord.com/api/download?platform=linux&format=deb
vsc=https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
```

Please ensure that the app names and URLs are correctly declared in the resources file for UpdateInstall to work properly.
