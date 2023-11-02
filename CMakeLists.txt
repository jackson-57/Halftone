cmake_minimum_required(VERSION 3.14)
set(CMAKE_C_STANDARD 11)

set(ENVSDK $ENV{PLAYDATE_SDK_PATH})

if (NOT ${ENVSDK} STREQUAL "")
	# Convert path from Windows
	file(TO_CMAKE_PATH ${ENVSDK} SDK)
else()
	execute_process(
			COMMAND bash -c "egrep '^\\s*SDKRoot' $HOME/.Playdate/config"
			COMMAND head -n 1
			COMMAND cut -c9-
			OUTPUT_VARIABLE SDK
			OUTPUT_STRIP_TRAILING_WHITESPACE
	)
endif()

if (NOT EXISTS ${SDK})
	message(FATAL_ERROR "SDK Path not found; set ENV value PLAYDATE_SDK_PATH")
	return()
endif()

set(CMAKE_CONFIGURATION_TYPES "Debug;Release")
set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

# Game Name Customization
set(PLAYDATE_GAME_NAME Halftone)
set(PLAYDATE_GAME_DEVICE Halftone_DEVICE)

project(${PLAYDATE_GAME_NAME} C ASM)

if (TOOLCHAIN STREQUAL "armgcc")
	# hack https://devforum.play.date/t/c-api-converting-string-to-float/10097/7
	set(CMAKE_EXE_LINKER_FLAGS "--specs=nosys.specs" CACHE INTERNAL "")

	add_executable(${PLAYDATE_GAME_DEVICE} main.c playback.c audio.c index.c image.c)
	# device is missing calloc implementation
#	target_sources(${PLAYDATE_GAME_DEVICE} PRIVATE buildsupport/calloc.c)

else()
	add_library(${PLAYDATE_GAME_NAME} SHARED main.c playback.c audio.c index.c image.c)
	# reimplements malloc, free, calloc, etc. with the Playdate API realloc to enable Malloc Log integration
	# only works on macOS, see https://devforum.play.date/t/c-api-why-isnt-setup-c-included-in-simulator-builds/12680/2
#	target_sources(${PLAYDATE_GAME_NAME} PRIVATE ${SDK}/C_API/buildsupport/setup.c buildsupport/calloc.c)
endif()


include(buildsupport/playdate_game.cmake)

set(OP_DISABLE_HTTP ON)
set(OP_DISABLE_DOCS ON)
set(OP_DISABLE_EXAMPLES ON)
set(OP_FIXED_POINT ON)
set(OPUS_FIXED_POINT ON)
set(OPUS_ENABLE_FLOAT_API OFF)
add_subdirectory(lib/opus)
add_subdirectory(lib/ogg)
add_subdirectory(lib/opusfile)
add_subdirectory(lib/speex_resampler)
add_subdirectory(lib/stb_image)

target_compile_definitions(speex_resampler PRIVATE FIXED_POINT)
target_compile_definitions(stb_image PUBLIC STBI_NO_STDIO STBI_ONLY_JPEG STBI_ONLY_PNG STBI_ONLY_GIF)

if (TOOLCHAIN STREQUAL "armgcc")
	target_compile_options(opus PUBLIC ${MCFLAGS})
	target_compile_options(opus PUBLIC -falign-functions=16 -fomit-frame-pointer)
	target_compile_options(opus PUBLIC -gdwarf-2)
	target_compile_options(opus PUBLIC -fverbose-asm)
	target_compile_options(opus PUBLIC -ffunction-sections -fdata-sections)
	target_compile_options(opus PUBLIC -mword-relocations -fno-common)

	target_compile_options(ogg PUBLIC ${MCFLAGS})
	target_compile_options(ogg PUBLIC -falign-functions=16 -fomit-frame-pointer)
	target_compile_options(ogg PUBLIC -gdwarf-2)
	target_compile_options(ogg PUBLIC -fverbose-asm)
	target_compile_options(ogg PUBLIC -ffunction-sections -fdata-sections)
	target_compile_options(ogg PUBLIC -mword-relocations -fno-common)

	target_compile_options(opusfile PUBLIC ${MCFLAGS})
	target_compile_options(opusfile PUBLIC -falign-functions=16 -fomit-frame-pointer)
	target_compile_options(opusfile PUBLIC -gdwarf-2)
	target_compile_options(opusfile PUBLIC -fverbose-asm)
	target_compile_options(opusfile PUBLIC -ffunction-sections -fdata-sections)
	target_compile_options(opusfile PUBLIC -mword-relocations -fno-common)

	target_compile_options(speex_resampler PUBLIC ${MCFLAGS})
	target_compile_options(speex_resampler PUBLIC -falign-functions=16 -fomit-frame-pointer)
	target_compile_options(speex_resampler PUBLIC -gdwarf-2)
	target_compile_options(speex_resampler PUBLIC -fverbose-asm)
	target_compile_options(speex_resampler PUBLIC -ffunction-sections -fdata-sections)
	target_compile_options(speex_resampler PUBLIC -mword-relocations -fno-common)

	target_compile_options(stb_image PUBLIC ${MCFLAGS})
	target_compile_options(stb_image PUBLIC -falign-functions=16 -fomit-frame-pointer)
	target_compile_options(stb_image PUBLIC -gdwarf-2)
	target_compile_options(stb_image PUBLIC -fverbose-asm)
	target_compile_options(stb_image PUBLIC -ffunction-sections -fdata-sections)
	target_compile_options(stb_image PUBLIC -mword-relocations -fno-common)

	target_link_libraries(${PLAYDATE_GAME_DEVICE} opusfile speex_resampler stb_image)
else()
	target_link_libraries(${PLAYDATE_GAME_NAME} opusfile speex_resampler stb_image)
endif()