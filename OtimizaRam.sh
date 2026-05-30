#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  OtimizaRam.sh — Otimizador de Ambiente para IAs no Termux
#  Libera recursos e configura threads para máxima performance.
#  Uso: bash OtimizaRam.sh [--silencioso] [--root]
# ============================================================

# ── Cores ────────────────────────────────────────────────────
V='\033[0;32m'   # verde
A='\033[0;33m'   # amarelo
R='\033[0;31m'   # vermelho
C='\033[0;36m'   # ciano
B='\033[1m'      # negrito
X='\033[0m'      # reset

# ── Flags ────────────────────────────────────────────────────
SILENCIOSO=false
ROOT=false
for arg in "$@"; do
  [[ "$arg" == "--silencioso" ]] && SILENCIOSO=true
  [[ "$arg" == "--root" ]]       && ROOT=true
done

log()  { $SILENCIOSO || echo -e "${C}[INFO]${X}  $*"; }
ok()   { $SILENCIOSO || echo -e "${V}[OK]${X}    $*"; }
warn() { $SILENCIOSO || echo -e "${A}[AVISO]${X} $*"; }
err()  { echo -e "${R}[ERRO]${X}  $*" >&2; }

# ── Banner ───────────────────────────────────────────────────
$SILENCIOSO || cat <<'EOF'
  ___  _   _           _            ____      _    __  __ 
 / _ \| |_(_)_ __ ___ (_)______ _  |  _ \    / \  |  \/  |
| | | | __| | '_ ` _ \| |_  / _` | | |_) |  / _ \ | |\/| |
| |_| | |_| | | | | | | |/ / (_| | |  _ <  / ___ \| |  | |
 \___/ \__|_|_| |_| |_|_/___\__,_| |_| \_\/_/   \_\_|  |_|
         Otimizador de recursos para IAs no Termux
EOF

# ── Funções de Memória ───────────────────────────────────────
mem_livre_mb() {
  awk '/MemAvailable/ {printf "%d", $2/1024}' /proc/meminfo
}

mem_total_mb() {
  awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo
}

# ── 1. Snapshot inicial ──────────────────────────────────────
ANTES=$(mem_livre_mb)
TOTAL=$(mem_total_mb)
echo ""
log "RAM total: ${B}${TOTAL} MB${X}  |  Livre antes: ${B}${ANTES} MB${X}"
log "Iniciando otimizações..."
echo ""

# ── 2. Liberar cache de pacotes do pkg (Termux) ──────────────
log "Limpando cache de pacotes (pkg)..."
if command -v pkg &>/dev/null; then
  pkg clean -y &>/dev/null && ok "Cache de pacotes limpo."
else
  warn "Comando pkg não encontrado, pulando."
fi

# ── 3. Remover arquivos temporários do Termux ────────────────
log "Removendo arquivos temporários..."
TMP_DIRS=(
  "$TMPDIR"
  "$PREFIX/tmp"
  "$HOME/.cache"
)
LIMPOS=0
for d in "${TMP_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    COUNT=$(find "$d" -mindepth 1 -maxdepth 2 -type f 2>/dev/null | wc -l)
    rm -rf "${d:?}"/* 2>/dev/null
    LIMPOS=$((LIMPOS + COUNT))
  fi
done
ok "~$LIMPOS arquivo(s) temporário(s) removido(s)."

# ── 4. Encerrar jobs em background do próprio Termux ─────────
log "Encerrando jobs em background da sessão atual..."
JOBS_MORTOS=0
while IFS= read -r job_pid; do
  [[ -n "$job_pid" && "$job_pid" != "$$" ]] && kill "$job_pid" 2>/dev/null && JOBS_MORTOS=$((JOBS_MORTOS+1))
done < <(jobs -p 2>/dev/null)
ok "$JOBS_MORTOS job(s) encerrado(s)."

# ── 5. Encerrar processos desnecessários no modo User ────────
PROC_DESNECESSARIOS=( "top" "htop" "btop" "vim" "nano" "less" "man" "wget" "curl" )
log "Limpando processos dispensáveis..."
MORTOS=0
for proc in "${PROC_DESNECESSARIOS[@]}"; do
  PIDS=$(pgrep -x "$proc" 2>/dev/null)
  if [[ -n "$PIDS" ]]; then
    kill $PIDS 2>/dev/null && MORTOS=$((MORTOS+1))
    warn "Encerrado: $proc"
  fi
done
[[ $MORTOS -eq 0 ]] && ok "Nenhum processo conflitante encontrado."

# ── 6. Otimizações de Kernel (Requer Root) ───────────────────
log "Verificando permissões de Root e Kernel..."
if $ROOT; then
  # Libera PageCache, dentries e inodes (Efetivo para liberar RAM)
  if su -c "sync; echo 3 > /proc/sys/vm/drop_caches" 2>/dev/null; then
    ok "Caches do kernel liberados (Drop Caches)."
  else
    err "Falha ao limpar caches do kernel. Verifique se possui permissões su."
  fi

  # Reduz Swappiness
  SWAP_FILE="/proc/sys/vm/swappiness"
  if su -c "echo 10 > $SWAP_FILE" 2>/dev/null; then
    ok "Swappiness reduzida para 10."
  else
    warn "Não foi possível alterar a swappiness."
  fi
else
  warn "Otimizações profundas puladas. Execute com '--root' se seu dispositivo for rooteado."
fi

# ── 7. Otimizar variáveis de ambiente para IAs ───────────────
log "Configurando ambiente para inferência de IA..."
CPUS=$(nproc 2>/dev/null || echo 4)
THREADS=$(( CPUS > 2 ? CPUS / 2 : 1 ))

PROFILE="$HOME/.termux_ai_profile"
cat > "$PROFILE" <<ENVFILE
# Gerado por OtimizaRam.sh — $(date)
export OMP_NUM_THREADS=$THREADS
export OPENBLAS_NUM_THREADS=$THREADS
export MKL_NUM_THREADS=$THREADS
export NUMEXPR_NUM_THREADS=$THREADS
export TOKENIZERS_PARALLELISM=false
export GGML_METAL=0
export LLAMA_NO_METAL=1
export LLAMA_CTX_SIZE=2048
ENVFILE

ok "Variáveis exportadas: Threads OMP limitadas a $THREADS."
ok "Perfil de IA salvo em: $PROFILE"

# ── 8. Dicas Rápidas ─────────────────────────────────────────
echo ""
$SILENCIOSO || echo -e "${B}${C}━━━  DICAS DE USO PARA IAs  ━━━${X}"
$SILENCIOSO || cat <<'TIPS'
  🦙 llama.cpp: Use '--ctx-size 2048' e '--n-gpu-layers 0' para evitar travamentos.
  🎨 stable-diffusion.cpp: Utilize modelos 'q4_0' (4-bit quantizados).
  🐍 Python/HF: Carregue modelos com 'torch_dtype="float16"'.
TIPS

# ── 9. Snapshot final ────────────────────────────────────────
DEPOIS=$(mem_livre_mb)
GANHO=$((DEPOIS - ANTES))

echo ""
$SILENCIOSO || echo -e "${B}${V}━━━  RESULTADO FINAL  ━━━${X}"
$SILENCIOSO || printf "  RAM livre antes : ${B}%4d MB${X}\n" "$ANTES"
$SILENCIOSO || printf "  RAM livre depois: ${B}%4d MB${X}\n" "$DEPOIS"

if [[ $GANHO -gt 0 ]]; then
  $SILENCIOSO || printf "  ${V}${B}Memória Liberada : +%4d MB ✔${X}\n" "$GANHO"
elif [[ $GANHO -eq 0 ]]; then
  $SILENCIOSO || printf "  ${A}Sistema já otimizado (0 MB alterado).${X}\n"
else
  $SILENCIOSO || printf "  ${A}Variação normal do Android: %4d MB${X}\n" "$GANHO"
fi

echo ""
ok "Pronto para rodar IAs locais! 🚀"
echo ""

# ── 10. Integração .bashrc ───────────────────────────────────
if ! $SILENCIOSO; then
  read -r -t 10 -p "$(echo -e "${C}Adicionar 'source ~/.termux_ai_profile' ao ~/.bashrc? [s/N]:${X} ")" RESP
  if [[ "${RESP,,}" == "s" ]]; then
    LINHA='source ~/.termux_ai_profile'
    if ! grep -qF "$LINHA" "$HOME/.bashrc" 2>/dev/null; then
      echo -e "\n# Otimizações de RAM para IA (OtimizaRam.sh)\n$LINHA" >> "$HOME/.bashrc"
      ok "Adicionado ao ~/.bashrc."
    else
      warn "O perfil já estava no seu ~/.bashrc."
    fi
  fi
fi

exit 0
