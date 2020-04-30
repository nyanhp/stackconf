using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Api.Classes
{
    public class RestaurantsDb
    {
        public static List<Restaurant> Restaurants = new List<Restaurant>()
            {
                new Restaurant(){Name = "Takumi", Cuisine = "Ramen", Id=0 },
                new Restaurant(){Name = "Ah-Un", Cuisine = "Teppanyaki", Id=1 },
                new Restaurant(){Name = "Kushi-Tei of Tokyo", Cuisine = "Izakaya", Id=2 }
            };
    }
}
