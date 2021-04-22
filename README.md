# sensu-plugins-elasticsearch-es-snapshots

Options :
~~~
-h elasticsearch host
-p elasticsearch port
-r elasticsearch repository
-s address scheme
~~~

Command example :
~~~
./bin/es-snapshots-last-state.sh -s https -h elasticsearch.localhost.local -p 9200 -r my_snapshot_repository
~~~