if status is-interactive
    # Commands to run in interactive sessions can go here
end

zoxide init --cmd cd fish | source
set PATH ~/.local/bin/ $PATH
alias vi=nvim
alias lv=lvim
alias venv='source venv/bin/activate.fish'
if test -x "$(command -v python)"
    alias newvenv='python -m venv .venv'
else if test -x "$(command -v python3)"
    alias newvenv='python3 -m venv .venv'
end
if test -x "$(command -v cargo)"
    set PATH ~/.cargo/bin/ $PATH
end
