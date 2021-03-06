#' @eval get_description('SVM')
#' @return struct object
#' @export SVM
#' @examples
#' M = SVM(factor_name='Species',gamma=1)
SVM = function(factor_name,kernel='linear',degree=3,gamma=1,coef0=0,cost=1,class_weights=NULL,...) {
    
    out=struct::new_struct('SVM',
        factor_name=factor_name,
        kernel=kernel,
        degree=degree,
        gamma=gamma,
        coef0=coef0,
        cost=cost,
        class_weights=class_weights,
        ...)
    return(out)
}

.SVM<-setClass(
    "SVM",
    contains='model',
    slots=c(
        factor_name='entity',
        kernel='enum',
        degree='entity',
        gamma='entity',
        coef0='entity',
        cost='entity',
        class_weights='entity',
        
        SV='matrix',
        index='numeric',
        coefs='matrix',
        pred='data.frame',
        decision_values='data.frame',
        
        SVM_model='entity'
    ),
    prototype = list(name='Support Vector Machine Classifier',
        
        type="classification",
        predicted='pred',
        libraries='e1071',
        description=paste0('Support Vector Machines (SVM) are a machine ',
            'learning algorithm for classification. They can make use of kernel ',
            'functions to generate highly non-linear boundaries between groups.'),
        .params=c('factor_name','kernel','degree','gamma','coef0','cost','class_weights'),
        .outputs=c('SV','index','coefs','pred','decision_values'),
        citations=list(
            bibentry(
                bibtype='Article',
                year = '2010',
                volume = 135,
                number = 2,
                pages = "230-267",
                author = as.person('Richard G. Brereton and Gavin R. Lloyd'),
                title = "Support Vector Machines for classification and regression",
                journal = "The Analyst"
            )
        ),
        factor_name=ents$factor_name,
        
        kernel=enum(value = 'linear',
            name = 'Kernel type',
            description = c(
                'linear' = '',
                'polynomial' = '',
                'radial'='',
                'sigmoid'=''
            ),
            type = 'character',
            allowed = c('linear','polynomial','radial','sigmoid')),
        
        degree=entity(value = 3,
            name = 'Polynomial degree',
            description = 'The polynomial degree',
            type = 'numeric'),
        
        gamma=entity(value = 1,
            name = 'Gamma parameter',
            description = 'The gamma parameter',
            type = 'numeric'),
        
        coef0=entity(value = 0,
            name = 'Offset coefficient',
            description = 'The offset coefficient',
            type = 'numeric'),
        
        cost=entity(value = 1,
            name = 'SVM cost parameter',
            description = 'The cost of violating the constraints',
            type = 'numeric'),
        
        class_weights=entity(value = 1,
            name = 'Class weights',
            description = paste0('A named vector of weights for the different classes.  Specifying 
            "inverse" will choose the weights inversely proportional to the class distribution.'),
            type = c('numeric','character','NULL')),
        
        SVM_model=entity(
            name = 'SVM model',
            description = 'SVM model from e1071 package',
            type = 'svm')
    )
)

#' @export
#' @template model_train
setMethod(f="model_train",
    signature=c("SVM",'DatasetExperiment'),
    definition=function(M,D) {
        
        # make class_weights a named list of length = 1
        if (length(M$class_weights==1)) {
            L=levels(D$sample_meta[[M$factor_name]])
            cw=rep(M$class_weights,length(L))
            names(cw)=L
            M$class_weights=cw
        } else {
            cw=M$class_weights
        }
        
        sv_model = e1071::svm(
            x=D$data, 
            y=D$sample_meta[[M$factor_name]],
            kernel=M$kernel,
            gamma=M$gamma,
            degree=M$degree,
            coef0=M$coef0,
            cost=M$cost,
            class.weights=cw,
            scale=FALSE
        )
        
        M$SV=sv_model$SV
        M$index=sv_model$index
        M$coefs=sv_model$coefs
        
        value(M@SVM_model)=sv_model
        
        return(M)
    }
)

#' @export
#' @template model_predict
setMethod(f="model_predict",
    signature=c("SVM",'DatasetExperiment'),
    definition=function(M,D) {
        
        out=predict(value(M@SVM_model),D$data,decision.values = TRUE)
        M$decision_values=data.frame(value=attributes(out)$decision.values)
        out=data.frame(svm_predicted=out)
        M$pred=out
        
        return(M)
    }
)






#' @eval get_description('svm_plot_2d')
#' @export svm_plot_2d
#' @examples
#' D = iris_DatasetExperiment()
#' M = filter_smeta(mode='exclude',levels='setosa',factor_name='Species') +
#'     mean_centre()+PCA(number_components=2)+
#'     SVM(factor_name='Species',kernel='linear')
#' M = model_apply(M,D)
#' 
#' C = svm_plot_2d(factor_name='Species')
#' chart_plot(C,M[4],predicted(M[3]))
#' 
svm_plot_2d = function(factor_name,npoints=100,...) {
    out=struct::new_struct('svm_plot_2d',
        factor_name=factor_name,
        npoints=npoints,
        ...)
    return(out)
}

.svm_plot_2d<-setClass(
    "svm_plot_2d",
    contains='chart',
    slots=c(
        # INPUTS
        factor_name='entity',
        npoints='entity'
    ),
    prototype = list(name='SVM scatter plot',
        description='A scatter plot of the input data by group and the calculated boundary of a SVM model.',
        type="scatter",
        libraries=c('e1071'),
        .params=c('factor_name','npoints'),
        
        factor_name=ents$factor_name,
        npoints=entity(name='Number of grid points',
            value=100,
            type='numeric',
            description='The number of grid points used to plot the boundary.'
        )
    )
    
)

#' @export
#' @template chart_plot
setMethod(f="chart_plot",
    signature=c("svm_plot_2d",'SVM'),
    definition=function(obj,dobj,gobj) {
        
        ## grid for plotting boundary
        n=obj$npoints
        hix=max(gobj$data[,1])
        lox=min(gobj$data[,1])
        hiy=max(gobj$data[,2])
        loy=min(gobj$data[,2])
        
        # expand by 10%
        hix=hix+(hix*0.05)
        lox=lox-(lox*0.05)
        hiy=hiy+(hiy*0.05)
        loy=loy-(loy*0.05)
        
        # create grid
        Z=matrix(0,nrow=n*n,2)
        Z[,1]=rep(seq(from=lox,to=hix,length.out=n),n)
        Z[,2]=sort(rep(seq(from=loy,to=hiy,length.out=n),n))
        Z=data.matrix(Z)
        
        SMz=Z
        VMz=Z[1:2,]
        
        Dz=DatasetExperiment(data=Z,sample_meta=SMz,variable_meta=VMz)
        
        # classify grid points
        eobj=model_predict(dobj,Dz)
        Z=cbind(Z,eobj$decision_values)
        colnames(Z)[1:2]=c('gx','gy')
        Z$pred=Z$decision_values
        
        A=data.frame(x=gobj$data[,1],y=gobj$data[,2],group=gobj$sample_meta[[dobj$factor_name]])
        
        # Scatter points
        g=ggplot()
        
        for (k in 1:ncol(dobj$decision_values)) {
            g=g+geom_contour(data=Z,aes_(x=~gx,y=~gy,z=Z[,k+2]),breaks=c(0),colour='#000000',size=1)
            g=g+geom_contour(data=Z,aes_(x=~gx,y=~gy,z=Z[,k+2]),breaks=c(-1,1),linetype=7,colour='#A9A9A9')
        }
        
        g = g + geom_point(data=A,aes_(x=~x,y=~y,colour=~group)) +
            structToolbox:::scale_colour_Publication(name=obj$factor_name) +
            structToolbox:::theme_Publication(base_size = 12)
        
        # Support vectors
        B=as.data.frame(dobj$SV)
        colnames(B)=c('xx','yy')
        g=g+geom_point(data=B,aes_(x=~xx,y=~yy),shape=1,colour='#A9A9A9',size=3)
        
        
        g=g+xlab(colnames(gobj$data)[1])+ylab(colnames(gobj$data)[2])
        return(g)
    }
)
