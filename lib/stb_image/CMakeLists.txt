cmake_minimum_required(VERSION 3.25)
project(stb_image C)

set(CMAKE_C_STANDARD 11)

add_library(stb_image stb_implementation.c)

target_include_directories(stb_image PUBLIC include)