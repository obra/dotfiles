# macOS-specific shell config (Homebrew-installed tools).
# Sourced from ~/.zshrc; deployed only on macOS (manifest 'macos' tag).

# z — directory jumper
[ -r /opt/homebrew/etc/profile.d/z.sh ] && . /opt/homebrew/etc/profile.d/z.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' > /dev/null 2>&1)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" > /dev/null 2>&1
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# ccache compiler shims
[ -d /opt/homebrew/opt/ccache/libexec ] && export PATH="/opt/homebrew/opt/ccache/libexec:$PATH"
