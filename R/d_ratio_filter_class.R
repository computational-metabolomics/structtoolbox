#' d_ratio filter
#'
#' filters features based on the d_ratio of technical variance vs sample variance
#' @export dratio_filter
#' @import pmp
dratio_filter<-setClass(
    "dratio_filter",
    contains = c('method'),
    slots=c(params.threshold='entity',
        params.qc_label='entity',
        params.factor_name='entity',
        outputs.filtered='entity',
        outputs.flags='entity',
        outputs.d_ratio='data.frame'
    ),
    prototype=list(name = 'd_ratio filter',
        description = 'Filters features by calculating the d_ratio and removing features below the threshold.',
        type = 'filter',
        predicted = 'filtered',

        params.threshold=entity(name = 'd_ratio filter',
            description = 'Features with d_ratio less than the threshold are removed.',
            value = 20,
            type='numeric'),

        params.qc_label=entity(name = 'QC label',
            description = 'Label used to identify QC samples.',
            value = 'QC',
            type='character'),

        params.factor_name=entity(name='Factor name',
            description='Name of sample meta column to use',
            type='character',
            value='V1'),

        outputs.filtered=entity(name = 'd_ratio filtered dataset',
            description = 'A dataset object containing the filtered data.',
            type='dataset',
            value=dataset()
        ),
        outputs.flags=entity(name = 'Flags',
            description = 'flag indicating whether the feature was rejected by the filter or not.',
            type='data.frame',
            value=data.frame()
        )

    )
)

#' @export
setMethod(f="method.apply",
    signature=c("dratio_filter","dataset"),
    definition=function(M,D)
    {
        # median QC samples
        QC=filter_smeta(mode='include',levels=M$qc_label,factor_name=M$factor_name)
        QC = method.apply(QC,D)
        QC = predicted(QC)$data
        QC=apply(QC,2,mad,na.rm=TRUE)

        # median samples
        S=filter_smeta(mode='exclude',levels=M$qc_label,factor_name=M$factor_name)
        S = method.apply(S,D)
        S = predicted(S)$data
        S=apply(S,2,mad,na.rm=TRUE)

        d_ratio=(QC/S)*100

        OUT=d_ratio<M$threshold

        M$d_ratio=data.frame(d_ratio=d_ratio,row.names=colnames(D$data))
        M$flags=data.frame(rejected=OUT,row.names = colnames(D$data))

        D$data=D$data[,-OUT]
        D$variable_meta=D$variable_meta[,-OUT]

        M$filtered=D

        return(M)
    }
)