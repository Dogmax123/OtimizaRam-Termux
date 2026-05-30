
# 🚀 OtimizaRam-Termux

**OtimizaRam** é um script utilitário para [Termux](https://termux.dev/) projetado especificamente para usuários que desejam executar **Inteligências Artificiais locais no Android** (como `llama.cpp`, `ollama`, `stable-diffusion.cpp`, e ferramentas do Hugging Face).

Rodar LLMs ou gerar imagens no celular consome muita RAM e exige gestão de threads de CPU. O Android frequentemente mata processos (OOM - Out of Memory) por falta de recursos. Este script atua de forma cirúrgica para contornar esses limites antes de você rodar sua IA.

---

## ✨ Funcionalidades

* **🧹 Limpeza de Cache & Arquivos:** Remove resíduos de pacotes (`pkg`), limpa pastas temporárias e lixeiras de sistema que ocupam RAM vital.
* **🔪 Encerramento de Processos:** Mata processos paralelos ociosos no Termux que podem roubar ciclos de processamento ou memória.
* **⚙️ Tunagem de Threads (Anti-Thrashing):** A maior causa de lentidão em IAs locais no Android é a saturação de CPU. O script calcula núcleos físicos e ajusta variáveis de ambiente matematicamente (`OMP_NUM_THREADS`, etc.) para rodar de forma paralela e fluida.
* **🛡️ Otimizações do Kernel (Com Root):** Para dispositivos com Magisk/Root, altera a *Swappiness* do sistema (diminuindo uso de swap de disco lento) e efetua `drop_caches` do Kernel.
* **💾 Perfil Automático:** Cria o arquivo `~/.termux_ai_profile` com o ambiente otimizado e (opcionalmente) injeta no seu `.bashrc`.

---

## 📥 Instalação

Abra o seu Termux e rode os seguintes comandos:

```bash
# Baixe o script diretamente do repositório
curl -O [https://raw.githubusercontent.com/SEU_USUARIO/OtimizaRam-Termux/main/OtimizaRam.sh](https://raw.githubusercontent.com/Dogmax123/OtimizaRam-Termux/main/OtimizaRam.sh)

# Dê permissão de execução
chmod +x OtimizaRam.sh
