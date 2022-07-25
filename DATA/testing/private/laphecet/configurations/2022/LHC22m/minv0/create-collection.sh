
for run in $(cat $1)
do
  cmd="alien_find /alice/data/2022/LHC22m/$run/raw \"o2_ctf_run*.root\" -x /alice/cern.ch/user/l/laphecet/run3/2022/LHC22m/minv0/$run/ctfs.xml"
  echo $cmd
  eval $cmd
done


