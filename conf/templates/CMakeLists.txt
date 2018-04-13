

set(ap_nf_executor "pbs" CACHE STRING "executor used by nextflow (e.g. pbs, slurm, etc.)")
set(ap_annotation_path "/to/replace" CACHE PATH "directory for the annotations used by the pipeline")
set(ap_singularity_image_path "/to/replace" CACHE PATH "directory for the singularity images used by the pipeline (when profile containers is used)")
set(ap_tools_path "/to/replace if ap_use_toolspath is ON" CACHE PATH "directory for the tools used by the pipeline (when profile toolsPath is used)")



if(${ap_use_containers})
    if(IS_DIRECTORY ${ap_singularity_image_path})
        message("${BoldGreen} OK - ap_singularity_image_path ${ap_singularity_image_path} exists ${ColourReset}")
   else()
        message(WARNING "${BoldRed} WARNING - ap_singularity_image_path ${ap_singularity_image_path} does not exist ${ColourReset}")
    endif()
endif()
#configure_file(containers.config.in ${CMAKE_CURRENT_BINARY_DIR}/containers.config @ONLY)
#install(FILES ${CMAKE_CURRENT_BINARY_DIR}/containers.config DESTINATION ${CMAKE_INSTALL_PREFIX}/conf)
 
if(${ap_use_toolspath})
    if(IS_DIRECTORY ${ap_tools_path})
        message("${BoldGreen} OK - ap_tools_path ${ap_tools_path} exists ${ColourReset}")
   else()
        message(WARNING "${BoldRed} WARNING - ap_tools_path ${ap_tools_path} does not exist ${ColourReset}")
    endif()
endif()
#configure_file(tools-path.config.in ${CMAKE_CURRENT_BINARY_DIR}/tools-path.config @ONLY)
#install(FILES ${CMAKE_CURRENT_BINARY_DIR}/tools-path.config DESTINATION ${CMAKE_INSTALL_PREFIX}/conf)
 
file (GLOB ap_conf_template_file_list "${CMAKE_CURRENT_SOURCE_DIR}/*.in")

foreach(file ${ap_conf_template_file_list})
  get_filename_component(file ${file} NAME)
  string(REGEX REPLACE ".in$" "" file_output ${file})
  message("configure: ${file} into ${CMAKE_CURRENT_BINARY_DIR}/${file_output}")

  configure_file(${file} ${CMAKE_CURRENT_BINARY_DIR}/${file_output} @ONLY)
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${file_output} DESTINATION ${CMAKE_INSTALL_PREFIX}/conf)

endforeach(file ${ap_conf_template_file_list})



