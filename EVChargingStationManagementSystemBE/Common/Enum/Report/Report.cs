using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Common.Enum.Report
{
    internal class Report { 
public enum ReportType
    {
        Bug,
        FeatureRequest,
        Maintenance,
        Other
    }

    public enum SeverityLevel
    {
        Low,
        Medium,
        High,
        Critical
    }

    public enum ReportStatus
    {
        Open,
        InProgress,
        Resolved,
        Closed
    }
}
}