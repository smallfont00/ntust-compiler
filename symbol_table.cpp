
#include "symbol_table.h"

#include <iostream>
#include <map>
#include <vector>

bool dynamic_type_check(type_* first, int code) {
    switch (code) {
        case TInt:
            return type_check<int>(first);
        case TFloat:
            return type_check<float>(first);
        case TString:
            return type_check<std::string>(first);
        case TBoolean:
            return type_check<bool>(first);
        case TChar:
            return type_check<char>(first);
        default:
            return false;
    }
};

type_* dynamic_type(int code) {
    switch (code) {
        case TInt:
            return new type<int>();
        case TFloat:
            return new type<float>();
        case TString:
            return new type<std::string>();
        case TBoolean:
            return new type<bool>();
        case TChar:
            return new type<char>();
        default:
            return new type<void>();
    }
};

bool same_type(type_* a, type_* b) {
    return dynamic_type_code(a) == dynamic_type_code(b);
}

int dynamic_type_code(type_* ty) {
    if (auto t = type_check<int>(ty)) return TInt;
    if (auto t = type_check<float>(ty)) return TFloat;
    if (auto t = type_check<std::string>(ty)) return TString;
    if (auto t = type_check<bool>(ty)) return TBoolean;
    if (auto t = type_check<char>(ty)) return TChar;
    return 0;
}

template <>
type<func>* value_cast(type_* ty) {
    if (auto func_ty = type_cast<func>(ty)) return func_ty->ret_val()->cast<func>();
}

void Symbol_table::add(const std::string& name, type_* ty) {
    if (ty) table[name] = ty;
}

type_* Symbol_table::find(const std::string& name) {
    if (auto p = table.find(name); p != table.end()) return p->second;
    return nullptr;
}

type_* Symbol_table::find_all(const std::string& name) {
    if (auto t = this->find(name); !t && this->parent)
        return this->parent->find_all(name);
    else
        return t;
}

bool Symbol_table::visiable(const std::string& name) {
    return (this->find(name) != nullptr) || (this->parent && this->parent->visiable(name));
}

bool Symbol_table::visiable(const std::string& first, const std::string& args...) {
    return this->visiable(first) || this->visiable(args);
}

bool Symbol_table::declare(const std::string& name, type_* ty) {
    if (auto t = this->find(name)) return false;
    this->add(name, ty);
    return true;
}

void Symbol_table::merge_from(const Symbol_table* other) {
    for (auto [key, ty] : other->table) {
        this->table[key] = ty;
    }
}

#define WRONG wrong(__LINE__)

int test_symbol() {
    using string = std::string;
    auto wrong = [](int code) { printf("Wrong at line: %d\n", code); };

    Symbol_table* sym_t = new Symbol_table();

    sym_t->add("a", new type<int>(12));
    sym_t->add("b", new type(false));
    sym_t->add("c", new type(string("I'm string")));
    sym_t->add("d", new type(1.2f));

    type_* x = TYPE(1);
    type_* y = DEFINE(float, 1);
    type_* z = DECLARE(bool);

    new type<func>(new type<int>(), {{"x", x}, {"y", y}});

    auto fun = DEFINE(func,
                      new type<int>(),
                      {{"x", x}, {"y", y}});

    //fun->add("z", z);

    type_* w = TYPE(2.0f);

    if (auto t = type_check<string, char>(x, y, z); t) WRONG;

    if (auto t = type_check<int, char>(x, y, z); !t) WRONG;

    if (auto t = type_check<char, float>(x, y, z); !t) WRONG;

    if (auto t = type_check<int>(w); t) WRONG;

    if (auto t = type_check<int, string>(w); t) WRONG;

    if (auto t = type_check<float, string>(w); !t) WRONG;

    if (auto t = type_check<string, float>(w); !t) WRONG;

    if (auto t = type_check<int>(x, w); !t) WRONG;

    if (auto t = type_check<int, string>(y, w); t) WRONG;

    if (auto t = type_check<float, string>(z, w); !t) WRONG;

    if (auto t = type_check<string, float>(w, y); !t) WRONG;

    if (auto t = x->test<float>(); t) WRONG;

    if (auto t = y->test<float>(); !t) WRONG;

    if (auto t = type_cast<int>(sym_t->find("a")); t->get() != 12) WRONG;

    if (auto t = type_cast<bool>(sym_t->find("b")); t->get() != false) WRONG;

    if (auto t = type_cast<string>(sym_t->find("c")); t->get() != "I'm string") WRONG;

    if (auto t = type_cast<float>(sym_t->find("d")); t->get() != 1.2f) WRONG;
    /*
    if (auto t = fun->check<int>("x"); !t) WRONG;

    if (auto t = fun->check<float>("y"); !t) WRONG;

    if (auto t = fun->check<bool>("z"); !t) WRONG;

    if (auto t = fun->check<int, bool>("a"); !t) WRONG;

    if (auto t = fun->check<bool, int>("b"); !t) WRONG;

    if (auto t = fun->check<string, int>("c"); !t) WRONG;

    if (auto t = fun->check<int>("d"); t) WRONG;

    if (auto t = fun->check<float>("e"); t) WRONG;

    if (auto t = fun->check<bool>("f"); t) WRONG;

    if (auto t = fun->check<float, string>("x"); t) WRONG;

    if (auto t = fun->check<int, char>("y"); t) WRONG;

    if (auto t = fun->check<string, int>("z"); t) WRONG;
    */
}
/*
int main() {
    test_symbol();
}
*/