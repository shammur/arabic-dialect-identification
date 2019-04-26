#!/bin/bash
stage=0

FEAT_TYPE=mfcc
N_FFT=400
HOP=160
VAD=True
CMVN=m
TRAIN_DATA=data/train_shuffle
EVAL_DATA=data/dev_shuffle
TOTAL_SPLIT=40
SAVE_FOLDER=data/tfrecords #DO NOT FIX
TOTAL_LANG=17


if [ $stage -eq 0 ]; then
# data preparation
# Shuffle (for training)
  for data in train dev; do
    python scripts/shuffle_data_segments.py data/${data} ${data}_shuffle
  done
# Split segments for parallel jobs
  for data in train_shuffle dev dev_shuffle ; do
    python scripts/split_data_segments.py data/${data} $TOTAL_SPLIT
  done
fi




if [ $stage -eq 1 ]; then
# Extract MFCC feature for NN input and save in tfrecords format
mkdir -p $SAVE_FOLDER
for data in train_shuffle dev; do
  for (( split=1; split<=$TOTAL_SPLIT; split++ )); do
    echo $split
    python scripts/prepare_data_wavlist_segments.py $FEAT_TYPE $N_FFT $HOP $VAD $CMVN 0 data/$data $TOTAL_SPLIT $split $SAVE_FOLDER
  done
done

data=dev_shuffle
python scripts/prepare_data_wavlist_segments.py $FEAT_TYPE $N_FFT $HOP $VAD $CMVN 0 $data $TOTAL_SPLIT 1 $SAVE_FOLDER


fi


if [ $stage -eq 2 ]; then
# train DNN model
  mkdir -p saver
  NN_MODEL=lang2vec
  LRATE=0.001
  INPUT_DIM=40
  BATCHSIZE=4
  FEAT_TYPE=${FEAT_TYPE}_fft${N_FFT}_hop${HOP}_vad_cmn
  START_ITER=0
  MAX_ITER=9000000
  VAL_SET_NAME=dev_shuffle #only first split will be used for validation
  FIXED_FRAME=200
  scripts/train_lang2vec.py lang2vec 0.001 $INPUT_DIM False $BATCHSIZE $FEAT_TYPE $TRAIN_DATA $TOTAL_SPLIT $TOTAL_LANG $START_ITER $MAX_ITER $VAL_SET_NAME $FIXED_FRAME

fi


