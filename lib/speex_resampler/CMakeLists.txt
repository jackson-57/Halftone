cmake_minimum_required(VERSION 3.25)
project(speex_resampler C)

set(CMAKE_C_STANDARD 11)

add_library(speex_resampler speexdsp/libspeexdsp/resample.c)

target_include_directories(speex_resampler PUBLIC include)