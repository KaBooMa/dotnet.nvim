# dotnet.nvim

Will become a wrapper for the `dotnet` CLI in Neovim.

## Install

Lazy:
```
{ 
    "KaBooMa/dotnet.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-telescope/telescope-file-browser.nvim"
    },
    opts = {}
}
```
### Current Features
- `Dotnet refactor namespaces` will scan the current working directory for any `.cs` files. 
  They are checked to see if their namespace matches their path. If not, you will be able to change them.
- `Dotnet project new` utilizes telescope to provide an easier way to create new projects from templates.
- **AUTOCOMMAND**: Opening an empty `.cs` file will trigger bootstrapping. This will check to see if the
  file is an interface or class. It will generate your namespace and declaration for you.
  - Interface is determined by `starts with I` and `second character is uppercase` at this time.
  - Class is the fallback pick.
