#!/bin/sh
#Путь к файлу логов
LOGFILE=/var/log/backup.log
#Код с которым была завершена предыдущая команда. Если команда была выполнена удачно, то значение этой переменной будет 0, если же неудачно то не 0. 
STATUS=$?

#Архив с файломи сайта
FILE1='/backup/files'
#Дамп базы
FILE2='/src/simplicator/dumper/backup/'$(ls -t --full-time /src/simplicator/dumper/backup/ | grep .sql.gz | awk '{if (NR < 2)printf("%s ",$9);}')
#Директория с архивами бэкапов тест сайта
FILE3='/backup/files_test'
#Путь до примонтированиого каталога FTP для файлов сайта
FTPDIRFILE='/mnt/temp-ftpfs/newsn1_backup/daily/files'
#Путь до примонтированиого каталога FTP для дампов базы
FTPDIRSQL='/mnt/temp-ftpfs/newsn1_backup/daily/sql'
#Путь до примонтированиого каталога FTP для файлов тестового сайта
FTPDIRFILETST='/mnt/temp-ftpfs/newsn1_backup/daily/files_test'

#Вывод текущей даты и времени
log(){
   message="$(date +"%y-%m-%d %T") $@"
   #echo $message
   echo $message >>$LOGFILE
}
adddate() {
    while IFS= read -r line; do
        echo "$(date +"%y-%m-%d %T") $line"
    done
}

log "Начало бэкапа"
function main
{
	log "Архивировани каталогов"
	cd /src/
	tar cfz $FILE1/$(date +"%Y%m%d.%H%M%S").tar.gz ./simplicator --exclude='img/knews' --exclude='samples' --exclude='log' --exclude='dumper' | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании каталогов"	
		exit
	fi

	# log "Архивировани каталогов тестового сайта"
	# cd /src/
	# tar cfz $FILE3/$(date +"%Y%m%d.%H%M%S").tar.gz ./simpltst --exclude='img/knews' --exclude='samples' --exclude='log' --exclude='dumper' | adddate
	# if [[ $? != 0 ]]; then
		# log "Ошибка при копировании каталогов"	
		# exit
	# fi
  
	log "Копирование на удаленный сервер"
  rsync -va -T '/tmp/' --no-perms --no-owner --no-group $FILE1/ $FTPDIRFILE/ | adddate
	if [[ $? != 0 ]]; then
		log "Ошибка при копировании на удаленный сервер"
		exit
	fi		
  
  # log "Копирование на удаленный сервер"
  # rsync -va -T '/tmp/' --no-perms --no-owner --no-group $FILE3/ $FTPDIRFILETST/ | adddate
	# if [[ $? != 0 ]]; then
		# log "Ошибка при копировании на удаленный сервер"
		# exit
	# fi	
  
	# log "Копирование SQL на удаленный сервер"
  # rsync -v -T '/tmp/' --no-perms --no-owner --no-group $FILE2/ $FTPDIRSQL/ | adddate
	# if [[ $? != 0 ]]; then
		# log "Ошибка при копировании на удаленный сервер"
		# exit
	# fi
  
	log "Удаляем все бэкапы кроме последнего" $FILE1
	cd $FILE1
	if [[ $? != 0 ]]; then
		log "Нет каталога " $FILE1
		exit
	fi
  	rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`

 	# log "Удаляем все бэкапы кроме последнего" $FILE3
	# cd $FILE3
	# if [[ $? != 0 ]]; then
		# log "Нет каталога " $FILE3
		# exit
	# fi
  	# rm -f `ls -t --full-time | awk '{if (NR > 2)printf("%s ",$9);}'`
    
    
	log "Удаляем все бэкапы кроме последних 2 из каталога " $FTPDIRFILE
	cd $FTPDIRFILE
	if [[ $? != 0 ]]; then
		log "Нет каталога " $FTPDIRFILE
		exit
	fi
  	rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'` 

  # log "Удаляем все бэкапы кроме последних 2 из каталога " $FTPDIRFILETST
	# cd $FTPDIRFILETST
	# if [[ $? != 0 ]]; then
		# log "Нет каталога " $FTPDIRFILETST
		# exit
	# fi
  	# rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'` 

	# log "Удаляем все бэкапы кроме последних 2 из каталога " $FTPDIRSQL
	# cd $FTPDIRSQL
	# if [[ $? != 0 ]]; then
		# log "Нет каталога " $FTPDIRSQL 
		# exit
	# fi
  	# rm -f `ls -t --full-time | awk '{if (NR > 3)printf("%s ",$9);}'`
    
log "Успешное окончание Бэкапа"
}

main 2>&1 | tee -a $LOGFILE

#Сокращаем лог файл
tail -n 1000  $LOGFILE >/tmp/backup_log.tmp
mv -f /tmp/backup_log.tmp $LOGFILE
