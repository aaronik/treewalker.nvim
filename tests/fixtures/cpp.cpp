/*
   Notice the lack of indentation inside the namespace.
   This style is used in for example the Google style guide,
   https://google.github.io/styleguide/cppguide.html#Namespaces
*/
namespace foo
{
struct A
{
    double x;
};

struct B
{
    double y;
};

struct C
{
    double z;
};

constexpr void bar(const A& a, const B& b, const C& c)
{
    // Do something with a, b, and c
}
}


