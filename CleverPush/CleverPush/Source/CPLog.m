#import <Foundation/Foundation.h>
#import "CPLog.h"

@implementation CPLog

static CP_LOGLEVEL _logLevel = CP_LOGLEVEL_INFO;
static CPLogListener _logListener;

+ (void)setLogLevel:(CP_LOGLEVEL)logLevel {
    _logLevel = logLevel;
}

+ (void)fatal:(NSString* _Nonnull)message, ... {
    va_list args;
    va_start(args, message);
    cleverpushLog(CP_LOGLEVEL_FATAL, message, args);
    va_end(args);
}

+ (void)error:(NSString* _Nonnull)message, ... {
    va_list args;
    va_start(args, message);
    cleverpushLog(CP_LOGLEVEL_ERROR, message, args);
    va_end(args);
}

+ (void)warn:(NSString* _Nonnull)message, ... {
    va_list args;
    va_start(args, message);
    cleverpushLog(CP_LOGLEVEL_WARN, message, args);
    va_end(args);
}

+ (void)info:(NSString* _Nonnull)message, ... {
    va_list args;
    va_start(args, message);
    cleverpushLog(CP_LOGLEVEL_INFO, message, args);
    va_end(args);
}

+ (void)debug:(NSString* _Nonnull)message, ... {
    va_list args;
    va_start(args, message);
    cleverpushLog(CP_LOGLEVEL_DEBUG, message, args);
    va_end(args);
}

+ (void)verbose:(NSString* _Nonnull)message, ... {
    va_list args;
    va_start(args, message);
    cleverpushLog(CP_LOGLEVEL_VERBOSE, message, args);
    va_end(args);
}

+ (void)setLogListener:(CPLogListener)listener {
    _logListener = listener;
}

void cleverpushLog(CP_LOGLEVEL logLevel, NSString* format, va_list args) {
    NSString* logLevelPrefix;
    switch (logLevel) {
        case CP_LOGLEVEL_FATAL:
            logLevelPrefix = @"FATAL";
            break;
        case CP_LOGLEVEL_ERROR:
            logLevelPrefix = @"ERROR";
            break;
        case CP_LOGLEVEL_WARN:
            logLevelPrefix = @"WARNING";
            break;
        case CP_LOGLEVEL_INFO:
            logLevelPrefix = @"INFO";
            break;
        case CP_LOGLEVEL_DEBUG:
            logLevelPrefix = @"DEBUG";
            break;
        case CP_LOGLEVEL_VERBOSE:
            logLevelPrefix = @"VERBOSE";
            break;
        default:
            logLevelPrefix = @"";
            break;
    }

    if (logLevel <= _logLevel) {
        NSString *logFormat = [NSString stringWithFormat:@"[CleverPush] %@: %@", logLevelPrefix, format];
        NSLogv(logFormat, args);

        if (_logListener) {
            NSString *outputString = [[NSString alloc] initWithFormat:format arguments:args];
            _logListener(outputString);
        }
    }
}

@end
