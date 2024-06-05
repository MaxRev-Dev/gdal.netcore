using System;

namespace MaxRev.Gdal.Core.Tests.NetFramework
{
    internal class Program
    {
        static void Main(string[] args)
        {
            GdalBase.ConfigureAll();
            Console.WriteLine("Gdal was configured successfully!");
            Console.ReadKey();
        }
    }
}
