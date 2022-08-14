#!/bin/bash

camp=mc16a
Camp=$(echo ${camp} | sed 's/mc/MC/g')
slimDir=tauSFCR

dsids=$(cat data/${camp}_all_April.list | grep -v "#" | cut -d . -f 3 | sort | uniq)
dsids=$(cat ../../MLntuple/gn1/usedDISDs.txt | grep -v "#")

# MVA splitExpr issue in MC??
cfg=/publicfs/atlas/atlasnew/higgs/hh2X/huirun/multilepton/leptau/sysProd/hhmlsysprod/HHMLSys/data/config_MC.conf

flist=tmp.flist
> ${flist}
for dsid in ${dsids}
do
  echo ${dsid}
  sample=$(cat data/${camp}_all_April.list | grep ${dsid})
  dupSamp=$(cat data/Cleanlist | grep ${dsid} | grep ${Camp} | grep root)
  outf=/publicfs/atlas/atlasnew/higgs/HHML/Slim_sys_prod/SlimSysNtups_Output/2LSS1Tau/${slimDir}/${camp}/${dsid}/
  lsample=(${sample})
  nsamp=${#lsample[@]}
  if [ ! -d "${sample}" -a ${nsamp} -eq 1 ];then echo "no ${dsid} dir, continue"; continue;fi
  if [ -d ${outf} ];then rm -r ${outf};fi
  if [ ! -d ${outf} ];then mkdir -p ${outf};fi
  if [ ${nsamp} -gt 1 ];then
    ls ${dupSamp}/*root >> ${flist}
    #echo listing dup...${dupSamp}
    echo listing dup
  elif [ ${nsamp} -eq 1 ];then
    ls ${sample}/*root >> ${flist}
    #echo listing...${sample}
    echo listing
  fi
done

#ldsids -> lfiles; numID -> numFile
ldsids=($(cat ${flist}))
numID=${#ldsids[@]}

intvl=10
seqs=$(seq 0 ${intvl} ${numID})

workarea=$(pwd)

allJobs=jobsSub.sh
> ${allJobs}

condor=condor
for init in ${seqs}
do
  fin=$((${init} + ${intvl} - 1))
  jobName=slimSys_${camp}_${init}_${fin}; echo ${jobName}
  hepout=${condor}/sub_${jobName}
  if [ ! -d ${hepout} ]; then mkdir -p ${hepout}; fi
  rm ${hepout}/* -r
  executable=${condor}/exe_${jobName}.sh
  > ${executable}
  #subcfg=${condor}/${jobName}.sub
  #> ${subcfg}

  echo "#!/bin/bash" >> ${executable}
  echo "" >> ${executable}
  echo "cd /publicfs/atlas/atlasnew/higgs/hh2X/huirun/multilepton/leptau/sysProd/hhmlsysprod/HHMLSys" >> ${executable}
  echo "export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase" >> ${executable}
  echo "source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh" >> ${executable}
  echo "source release_setup.sh" >> ${executable}
  echo "cd ${workarea}" >> ${executable}
  #echo "export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase" >> ${executable}
  #echo "source \${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh" >> ${executable}
  #echo "lsetup \"root 6.20.06-x86_64-centos7-gcc8-opt\"" >> ${executable}

  echo "" >> ${executable}
  echo "tini=\$(date +\"%Y-%m-%d %H-%M-%S\")" >> ${executable}
  echo "echo \"STARTED\"" >> ${executable}
  echo "echo \${tini}" >> ${executable}

for it in $(seq ${init} 1 ${fin})
do
  if [ ${it} -ge ${numID} ];then continue;fi
  echo "----- ${it}"
  inf=${ldsids[${it}]}
  dsid=$(echo ${inf} | cut -d . -f 3)
  #dir=$(ls -d gn1/${camp}/*${dsid}*)
  #subfs=$(ls ${dir}/*)
  #subfslist=
  #for file in ${subfs}
  #do
  #  subfslist="${subfslist} ${file}"
  #done
  #echo ${subfslist}

  outf=/publicfs/atlas/atlasnew/higgs/HHML/Slim_sys_prod/SlimSysNtups_Output/2LSS1Tau/${slimDir}/${camp}/${dsid}/

  echo "" >> ${executable}
  #echo "python dumpleptau.py -s branchList.txt ${subfslist} -o /eos/user/h/huirun/multilepton/leptau/gn2/${camp}/${dsid}.root -b" >> ${executable}
  echo "runHHMLSys --sp ${inf} --conf ${cfg} --out ${outf} --mcRun ${camp}" >> ${executable}
done
  echo "" >> ${executable}
  echo "tfin=\$(date +\"%Y-%m-%d %H-%M-%S\")" >> ${executable}
  echo "echo \${tfin}" >> ${executable}
  echo "echo \"COMPLETED\"" >> ${executable}

  #cat example.sub | sed 's/??/'${jobName}'/g' > ${subcfg}

  #echo "condor_submit ${subcfg}" >> ${allJobs}

  chmod +x ${executable}

  #echo "hep_sub ${executable} -g atlas -os CentOS7 -wt mid -mem 4096 -o ${hepout}/log-0.out -e ${hepout}/log-0.err" >> ${allJobs}
  echo "hep_sub ${executable} -o ${hepout}/log-0.out -e ${hepout}/log-0.err" >> ${allJobs}

  echo ""
done
