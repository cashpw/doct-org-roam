# doct-org-roam

Doct for org-roam

Copied from https://gist.github.com/vherrmann/f9b21eeea7d7c9123dc400a30599d50d into a repository for easy installation into Emacs via `package!`.

## Usage

> This is a revision of the gist by @progfolio which changes the file target keywords so that the code works with org-roam-capture-templates.
> 
> Example usage:
> 
> ```elisp
> (setq org-roam-capture-templates
>       (doct-org-roam
>        `("Note" :keys "n" :template "%?"
>          :type plain
>          :file "%<%Y%m%d%H%M%S>-${slug}.org"
>          :head ("#+title: ${title}"
>                 ""
>                 ""))))
> ```
> 
> ([source](https://gist.github.com/vherrmann/f9b21eeea7d7c9123dc400a30599d50d?permalink_comment_id=4063298#gistcomment-4063298))

## Installation

### Via `package!` in [Doom Emacs](https://github.com/doomemacs/doomemacs)

```elisp
# In package file
(package! doct-org-roam
  :recipe (:host github
           :repo "cashpw/doct-org-roam"))
           
# In config file
(use-package! doct-org-roam)
```
