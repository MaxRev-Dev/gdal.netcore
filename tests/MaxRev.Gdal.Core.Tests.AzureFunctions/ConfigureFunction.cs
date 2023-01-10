using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace MaxRev.Gdal.Core.Tests.AzureFunctions
{
    public static class ConfigureFunction
    {
        static ConfigureFunction()
        {
            GdalBase.ConfigureAll();
        }

        [FunctionName("ConfigureFunction")]
        public static Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest req,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            var result = RunConfigureCore(req, log);

            return Task.FromResult<IActionResult>(new OkObjectResult("Gdal configured: " + result));
        }

        [FunctionName("ConfigureFunctionCore")]
        public static bool RunConfigureCore(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest req,
            ILogger log)
        {
            return GdalBase.IsConfigured;
        }
    }
}

