using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core
{
    /// <summary>
    /// Configures all variables and options for GDAL including plugins and proj.db path
    /// </summary>
    public static class GdalBase
    {
        /// <summary>
        /// Shows if gdal is already initialized.
        /// </summary>
        public static bool IsConfigured { get; private set; }

        /// <summary>
        /// Performs search for gdalplugins and calls 
        /// <see cref="OSGeo.GDAL.Gdal.AllRegister"/> and <see cref="OSGeo.OGR.Ogr.RegisterAll"/>
        /// </summary>
        public static void ConfigureGdalDrivers()
        {
            if (IsConfigured) return;

            OSGeo.GDAL.Gdal.AllRegister();
            OSGeo.OGR.Ogr.RegisterAll();

            // set flag only on success
            IsConfigured = true;
        }

        /// <summary>
        /// Calls <see cref="ConfigureGdalDrivers"/> and <see cref="Proj.Configure"/>
        /// </summary> 
        public static void ConfigureAll()
        {
            if (IsConfigured) return;

            ConfigureGdalDrivers();

            Proj.Configure();
        }
    }
}
