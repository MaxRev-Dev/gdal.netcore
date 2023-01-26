using MaxRev.Gdal.Core.Tests.AzureFunctions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace GdalCore_XUnit
{
    [Collection("Sequential")]
    public class FunctionsTests
    {
        [Fact]
        public void FunctionConfiguringWorks()
        {
            var context = new DefaultHttpContext();
            var request = context.Request;
            var response = ConfigureFunction.RunConfigureCore(request, NullLogger.Instance);

            Assert.True(response);
        }
    }
}
