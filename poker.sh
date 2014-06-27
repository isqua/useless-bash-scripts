#!/bin/bash

# Объявляем массив, в котором помечаем использованные карты
declare -a used
used[52]=1

COMB=""

# Функция, которая возвращает случайную карту
function card() {
# Отдельно получим случайную масть и случайную стоимость, для более ровных вероятностей
  local c=52
  until [ "${used[$c]}" = "" ] && [ $c -lt 52 ]; do
    let "s = $RANDOM % 4" # Определяем масть (от 0 до 4)
    let "d = $RANDOM % 13" # Определяем стоимость (от 0 до 13)
    let "c = $s * 13 + $d"
  done
  used[$c]=1
#  echo $c
}

# Функция, которая выводит карты
function pcard() {
  # Чтобы вывести цветные карты, нужно использовать escape-последовательности
  te='\033[0m' # Конец последовательности
  a_s=(" ♥" " ♣" " ♦" " ♠") # Массив мастей
  a_d=(" 2" " 3" " 4" " 5" " 6" " 7" " 8" " 9" "10" " J" " Q" " K" " A") # Массив значений
  local s1=""
  local s2=""
  for i in $@
  do
    let "d = $i % 13"
    let "s = $i / 13"
    let "o = $s % 2"
    if [ "$o" = "1" ]; then
      tn='\E[30;47m' # Чёрный текст на белом фоне
    else
      tn='\E[31;47m' # Красный текст на белом фоне
    fi
    s1="$s1$tn${a_d[$d]} $te " # В первую строку выводим стоимость
    s2="$s2$tn${a_s[$s]} $te " # Во вторую выводим масть
  done
  echo
  echo -e $s1 # Выводим первую строку
  echo -e $s2 # Выводим вторую строку
}

if [ $# = 0 ]; then # Если аргументов нет, то
# Получаем случайных 5 карт
  card
  card
  card
  card
  card
elif [ $# = 5 ]; then
  for i in $@
  do
    used[$i]=1
  done
else
  echo "Please insert five cards or start the script widthout parameters"
  exit 1
fi

# Находим их список, упорядоченный по возрастанию
i=0
j=0
declare -c C # Объявляем массив карт
while [ $i -lt 52 ]; do # Запоминаем их индексы в порядке возрастания
  if [ "${used[$i]}" = "1" ]; then
    C[$j]=$i
    let "j+=1"
  fi
  let "i+=1"
done

# Печатаем карты
pcard "${C[*]}" # Все аргументы массива

function flush() {
  let "s1 = $1 / 13" # Узнаём масть первой карты
  let "s2 = $5 / 13" # Узнаём масть последней карты
  if [ $s1 = $s2 ]; then # Если их масти равны, то это какой-н flush
    let "s = $5 - $1" # Разность первой и последней карты
    if [ $s = 4 ]; then # Если равна четырём, то это straight flush
      let "s = $5 % 13" # Последняя карта
      if [ $s = 12 ]; then # Если последняя карта туз
        COMB="Royal Flush" # То это Роял Флэш
      else # А если нет
        COMB="Straight Flush" # То Страйт Флеш
      fi
    else # А если разность карт не равна четырём
      COMB="Flush" # То это просто Флеш
    fi
  fi
}

function kind()
{
  declare -a o
  local s=""
  for i in $@
  do
    let "c = $i % 13"
    let "o[$c] = ${o[$c]}+1"
  done
  i=0
  while [ $i -lt 13 ]; do 
      local a="${o[$i]}"
      if [ "$a" != "" ]; then
        s=$s${o[$i]}
      fi
      let "i += 1"
  done
  if [ ${#s} = 5 ]; then
    COMB="High Card"
  elif [ ${#s} = 4 ]; then
    COMB="One Pair"
  elif [ ${#s} = 3 ]; then
    if [ `echo $s | grep 2` ]; then
      COMB="Two Pairs"
    else
      COMB="Set"
    fi
  elif [ ${#s} = 2 ]; then
    if [ `echo $s | grep 2` ]; then
      COMB="Full House"
    else
      COMB="Quads"
    fi
  fi 
}

kind ${C[*]}
flush ${C[*]}

echo
echo -e '\033[1m'"$COMB"'\033[0m'
echo

