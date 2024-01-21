if status is-interactive
    # Commands to run in interactive sessions can go here
end

# device-specific config
source pc2.fish

alias vi=nvim
alias lv=lvim
alias venv='source venv/bin/activate.fish'
if test -x "$(command -v python)"
    alias newvenv='python -m venv .venv'
else if test -x "$(command -v python3)"
    alias newvenv='python3 -m venv .venv'
end
