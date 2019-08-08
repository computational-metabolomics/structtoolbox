#' sbcms
#'
#' Signal/batch correction using SMCBMS package
#' @export sb_corr
#' @examples
#' M = sb_corr()
sb_corr<-setClass(
    "sb_corr",
    contains = c('method'),
    slots=c(
        params.order_col='entity',
        params.batch_col='entity',
        params.qc_col='entity',
        params.smooth='entity',
        params.use_log='entity',
        params.min_qc='entity',
        outputs.corrected='entity'
    ),

    prototype=list(
        name = 'Signal/batch correction for mass spectrometry data',
        description = 'Applies Quality Control Robust Spline (QC-RSC) method to
        correct for signal drift and batch differences in mass spectrometry data.',
        type = 'correction',
        predicted = 'corrected',

        params.order_col=entity(
            name = 'Sample run order column',
            description = 'The column name of sample_meta indicating the run order of the samples.',
            value = character(0),
            type='character'),

        params.batch_col=entity(
            name = 'Batch ID column',
            description = 'The column name of sample_meta indicating the batch each sample was measured in.',
            value = character(0),
            type='character'),

        params.qc_col=entity(
            name = 'Class ID column',
            description = 'The column name of sample_meta indicating the group each sample is a member of.',
            value = character(0),
            type='character'),

        params.smooth=entity(
            name = 'Spline smoothing parameter',
            description = 'Should be in the range 0 to 1. If set to 0 (default) it will be estimated using
            leave-one-out cross-validation.',
            value = 0,
            type='numeric'),

        params.use_log=entity(
            name = 'Use log transformed data',
            description = 'TRUE or FALSE to perform the signal correction fit on the log scaled data. Default is TRUE.',
            value = 0,
            type='numeric'),

        params.min_qc=entity(
            name = 'Minimum number of QCs',
            description = 'Minimum number of QC samples required for signal correction.',
            value = 4,
            type='numeric'),

        outputs.corrected=entity(name = 'Signal/batch corrected dataset',
            description = 'THe dataset after signal/batch correction has been applied.',
            type='dataset',
            value=dataset()
        )
    )
)

#' @export
setMethod(f="method.apply",
    signature=c("sb_corr","dataset"),
    definition=function(M,D)
    {
        rn=rownames(D$data)
        cn=colnames(D$data)
        # uses transposed data
        X=as.data.frame(t(D$data))

        # apply correction
        corrected_data <- sbcms::QCRSC(
            df=X,
            order=D$sample_meta[[M$order_col]],
            batch=D$sample_meta[[M$batch_col]],
            classes=D$sample_meta[[M$qc_col]],
            spar=M$smooth,
            minQC=M$min_qc,
            log=M$use_log
        )

        D$data=as.data.frame(t(corrected_data))
        rownames(D$data)=rn
        colnames(D$data)=cn

        M$corrected=D
        return(M)
    }
)