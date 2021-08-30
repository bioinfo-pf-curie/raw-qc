/* 
 * Make Reports
 */

/* 
 * include requires tasks 
 */

include { makeReport } from '../process/makeReport' 
include { makeReport4RawData } from '../process/makeReport4RawData' 

/***********************
 * Header and conf
 */
ReportCh  = Channel.empty()
AdaptorCh = Channel.empty()

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
      ReportCh  = makeReport.out.trimReport
      AdaptorCh = makeReport.out.trimAdaptor
    }else{
      
      makeReport4RawData(
        readFilesCh
      )
      ReportCh  = makeReport4RawData.out.trimReport
    }
    emit:
       trimReportCh  = ReportCh
       trimAdaptorCh = AdaptorCh
}
    

    