/* 
 * Make Reports
 */

/* 
 * include requires tasks 
 */

include { makeReport } from '../process/makeReport' 
include { makeReport4RawData  } from '../process/makeReport4RawData ' 

/***********************
 * Header and conf
 */


workflow makeReportsFlow {
    // required inputs
    take: 
     readFilesCh
     trimReadsCh
     trimReportsCh
    // workflow implementation
    main:
    if (!params.skipTrimming){
      makeReport(
        readFilesCh.join(trimReadsCh).join(trimReportsCh)
      )
      emit:
       trimReportCh  = makeReport.out.trimReport
       trimAdaptorCh = makeReport.out.trimAdaptor
    }else{
      
      makeReport4RawData(
        readFilesCh
      )
      emit:
       trimReportCh  = makeReport4RawData.out.trimReport
       trimAdaptorCh = Channel.empty()
    }
    

    