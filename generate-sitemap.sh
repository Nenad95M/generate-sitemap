#!/usr/bin/env bash
#
# Upotreba:
#   ./generate_sitemap.sh [URL_SAJTA] [PRIMARY_LANG] [LANG1] [LANG2] ...
#
# Primer:
#   ./generate_sitemap.sh https://gabrielinkutak.com sr en de ru
#
# - Prvi argument:  domen / URL (bez koske na kraju, po mogućstvu).
# - Drugi argument: primarni jezik (npr. sr).
# - Sledeći argument(i): dodatni jezici (en, de, ru...).
#
# Skripta kreira sitemap.xml u istom folderu gde se nalazi.
# Root folder tretira kao primarni jezik.

######################################
# 0) Putanja do skripte i fajla sitemap.xml
######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTFILE="$SCRIPT_DIR/sitemap.xml"

######################################
# 1) Preuzimanje argumenata
######################################
if [ $# -lt 2 ]; then
  echo "Greška: Potrebno je bar 2 argumenta!"
  echo "Upotreba: $0 [URL_SAJTA] [PRIMARY_LANG] [LANG1] [LANG2] ..."
  exit 1
fi

DOMAIN="$1"           # npr. https://gabrielinkutak.com
PRIMARY_LANG="$2"     # npr. sr
shift 2               # skloni prva dva argumenta, ostali su LANGUAGES
LANGUAGES=("$@")      # ostatak jezika (en, de, ru, ...)

######################################
# 2) Funkcija za datum poslednje izmene
######################################
get_lastmod() {
  local file="$1"
  date -r "$file" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d"
}

######################################
# 3) Funkcija za prioritet
#    (index.html = 1.0, ostalo = 0.8)
######################################
get_priority() {
  local basename="$1"
  if [[ "$basename" == "index.html" ]]; then
    echo "1.0"
  else
    echo "0.8"
  fi
}

######################################
# 4) Započinjemo sitemap.xml
######################################
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"'
  echo '        xmlns:xhtml="http://www.w3.org/1999/xhtml">'

  ######################################
  # 4A) Da li postoji index.html u root-u
  ######################################
  if [[ -f "$SCRIPT_DIR/index.html" ]]; then
    basefile="index.html"
    lastmod="$(get_lastmod "$SCRIPT_DIR/$basefile")"
    priority="$(get_priority "$basefile")"

    echo "  <url>"
    echo "    <loc>$DOMAIN/$basefile</loc>"
    echo "    <lastmod>$lastmod</lastmod>"
    echo "    <priority>$priority</priority>"

    # Samo za index.html radimo alt linkove:
    # Primarni jezik:
    echo "    <xhtml:link rel=\"alternate\" hreflang=\"$PRIMARY_LANG\" href=\"$DOMAIN/$basefile\"/>"

    # Ostali jezici za index.html:
    for lang in "${LANGUAGES[@]}"; do
      # Ako postoji npr. en/index.html ili de/index.html
      if [[ -f "$SCRIPT_DIR/$lang/index.html" ]]; then
        echo "    <xhtml:link rel=\"alternate\" hreflang=\"$lang\" href=\"$DOMAIN/$lang/index.html\"/>"
      fi
    done

    echo "  </url>"
  fi

  ######################################
  # 4B) Ostali .html fajlovi u root-u (primarni jezik),
  #     ali != index.html => bez alt linkova
  ######################################
  for file in "$SCRIPT_DIR"/*.html; do
    [[ -f "$file" ]] || continue
    basename="$(basename "$file")"
    [[ "$basename" == "index.html" ]] && continue

    lastmod="$(get_lastmod "$file")"
    priority="$(get_priority "$basename")"

    echo "  <url>"
    echo "    <loc>$DOMAIN/$basename</loc>"
    echo "    <lastmod>$lastmod</lastmod>"
    echo "    <priority>$priority</priority>"
    echo "  </url>"
  done

  ######################################
  # 4C) Fajlovi u folderima ostalih jezika
  #     index.html preskačemo (jer je alt za primarni).
  #     Ostale .html fajlove stavljamo bez alt linkova.
  ######################################
  for lang in "${LANGUAGES[@]}"; do
    # Ako ne postoji folder, preskoči
    [[ -d "$SCRIPT_DIR/$lang" ]] || continue

    for lfile in "$SCRIPT_DIR/$lang"/*.html; do
      [[ -f "$lfile" ]] || continue
      lname="$(basename "$lfile")"

      # Ako je index.html, preskačemo (već alt za primarni)
      [[ "$lname" == "index.html" ]] && continue

      lastmod="$(get_lastmod "$lfile")"
      priority="$(get_priority "$lname")"

      echo "  <url>"
      echo "    <loc>$DOMAIN/$lang/$lname</loc>"
      echo "    <lastmod>$lastmod</lastmod>"
      echo "    <priority>$priority</priority>"
      echo "  </url>"
    done
  done

  echo '</urlset>'
} > "$OUTFILE"

echo "Generisan sitemap: $OUTFILE"
