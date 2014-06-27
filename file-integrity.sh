#!/bin/bash
# file-integrity.sh: Проверка целостности файлов в заданном каталоге

function usage() {
  echo "Usage: $0 [options] [mask]"
  echo " -t <type> тип шифрования (md5 или sha256)"
  exit 1
}

TYPE="md5"
MASK="*"

if [ $# = 0 ]; then # Если нет аргументов командной строки

  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    read -p "Сменить алгоритм хеширования с md5 на sha256? (y/n): " a
    if [ "$a" = "y" ]; then
      TYPE="sha256"
    fi
  done

  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    read -p "Сжать базу данных? (y/n): " a
    if [ "$a" = "y" ]; then
      ARCH=1
    fi
  done

  read -p "Укажите маску файлов, которые нужно указать в базе: " MASK

else # Если они есть

  while getopts "ct:m:" OPTION; do # Считываем опции
    case "$OPTION" in
      c)  ARCH="1" ;; # Сжимать файл базы
      t)  TYPE="$OPTARG" ;; # Тип (md5 или sha256)
      h)  usage ;; # Выводим справку
      m)  MASK="$OPTARG" ;; # Убираем подтверждения
      *)  usage ;; # Выводим справку
    esac
  done
  shift $(($OPTIND - 1)) # Перемещаем указатель на следующий аргумент
fi

if [ -z  "$1" ]
then
  directory="$PWD"      #  Если каталог не задан,
else                    #+ то используется текущий каталог.
  directory="$1"
fi

# Запоминаем имя каталога
t=`pwd`
cd "$directory"
directory=`pwd`
cd "$t"

E_DIR_NOMATCH=70
E_BAD_DBFILE=71

# Файл базы данных
if [ "$TYPE" = "md5" ]; then
  dbfile=File_record.md5
else
  dbfile=File_record.sha256
fi

if [ -f File_record.7z ]; then # Если есть заархивированная база
  7z x File_record.7z # Разархивируем её
fi

dbsum () {
  if [ -f "$1" ]; then # Если файл существует
    if [ "$TYPE" = "sha256" ]; then
      echo $( sha256sum "$1" )
    else
      echo $( md5sum "$1" )
    fi
  fi
}

set_up_database () {
  echo ""$directory"" > "$dbfile" # Записываем в файл имя директории
  for i in `find $directory -maxdepth 1 -name "$MASK"`
  do
    dbsum $i >> "$dbfile"
  done
}

check_database ()
{
  local n=0
  local filename
  local checksum

  if [ ! -r "$dbfile" ]
  then
    echo "Не могу прочитать файл с контрольными суммами!"
    exit $E_BAD_DBFILE
  fi

  while read record[n]
  do

    directory_checked="${record[0]}"
    if [ "$directory_checked" != "$directory" ]
    then
      echo "Имя каталога не совпадает с записаным в файле!"
      # Попытка использовать файл контрольных сумм для другого каталога.
      exit $E_DIR_NOMATCH
    fi

    if [ "$n" -gt 0 ]   # Не имя каталога.
    then
      filename[n]=$( echo ${record[$n]} | awk '{ print $2 }' )
      #  md5sum записывает в обратном порядке,
      #+ сначала контрольную сумму, затем имя файла
      checksum[n]=$( dbsum "${filename[n]}" )

      if [ "${record[n]}" = "${checksum[n]}" ]
      then
        echo "Файл ${filename[n]} не был изменен."
      else
        echo "ОШИБКА КОНТРОЛЬНОЙ СУММЫ для файла ${filename[n]}!"
        # Файл был изменен со времени последней проверки.
      fi

    fi

    let "n+=1"
  done <"$dbfile" # Чтение контрольных сумм из файла.
    
}

if [ ! -r "$dbfile" ]; then # Если файла с контрольными суммами не существует
  a=""
  until [ "$a" = "y" ] || [ "$a" = "n" ]; do
    read -p "Файл с контрольными суммами не создан. Создать? (y/n): " a
    if [ "$a" = "y" ]; then
      echo "Создание файла с контрольными суммами, \""$directory"/"$dbfile"\"."; echo
      set_up_database # Заводим базу данных
    else
      exit
    fi
  done
fi

check_database # Проверяем базу данных

if [ "$ARCH" = 1 ]; then # Если надо архивировать 
  if 7z a File_record.7z $dbfile; then
    rm $dbfile # Архивируем
  fi
fi

echo

exit 0

