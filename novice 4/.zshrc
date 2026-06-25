cat > ~/.zshrc << 'EOF'
# Novice project env vars
export SUPABASE_URL="https://gerdmqulomndzsdnksnd.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlcmRtcXVsb21uZHpzZG5rc25kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4NjIxNTcsImV4cCI6MjA5NzQzODE1N30.8toJtZWcV-eA_wgxBOOCcu2-qviNpb4YyhkFDMY4WUs"
export RESEARCHER_PIN=2026

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF