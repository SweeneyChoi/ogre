#-------------------------------------------------------------------
# This file is part of the CMake build system for OGRE
#     (Object-oriented Graphics Rendering Engine)
# For the latest info, see http://www.ogre3d.org/
#
# The contents of this file are placed in the public domain. Feel
# free to make use of it in any way you like.
#-------------------------------------------------------------------

############################################################
# MeshLodGenerator optional component
############################################################

PROJECT(OgreMeshLodGenerator)

# define header and source files for the library
file(GLOB HEADER_FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h")
file(GLOB SOURCE_FILES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")

# Add needed definitions 
add_definitions(-DOGRE_MESHLODGENERATOR_EXPORTS ${OGRE_VISIBILITY_FLAGS})

# include headers
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)
# repeat for PCH
include_directories("${OGRE_SOURCE_DIR}/OgreMain/include" "${OGRE_BINARY_DIR}/include")

# setup target
get_native_precompiled_header(OgreMeshLodGenerator)
add_library(OgreMeshLodGenerator ${OGRE_COMP_LIB_TYPE} ${OgreMeshLodGenerator_pch} ${HEADER_FILES} ${SOURCE_FILES} ${PLATFORM_HEADER_FILES} ${PLATFORM_SOURCE_FILES})
set_target_properties(OgreMeshLodGenerator PROPERTIES VERSION ${OGRE_SOVERSION} SOVERSION ${OGRE_SOVERSION})
target_link_libraries(OgreMeshLodGenerator OgreMain)
add_native_precompiled_header(OgreMeshLodGenerator "${CMAKE_CURRENT_SOURCE_DIR}/src/OgreMeshLodPrecompiledHeaders.h")

if (OGRE_CONFIG_THREADS)
  target_link_libraries(OgreMeshLodGenerator ${OGRE_THREAD_LIBRARIES})
endif ()

# install 
ogre_config_framework(OgreMeshLodGenerator)
ogre_config_component(OgreMeshLodGenerator)

install(FILES ${HEADER_FILES}
  DESTINATION include/OGRE/MeshLodGenerator
)
