#pragma once

#include <iostream>
#include <map>
#include <vector>

class Symbol_table;
class type_;

template <class T>
class type;

class func;

template <class T>
type<T>* type_cast(type_* ty) {
    return dynamic_cast<type<T>*>(ty);
};

template <class T>
type<T>* value_cast(type_* ty) {
    return type_cast<T>(ty);
}

class type_ {
   protected:
    bool is_constant;
    bool is_assigned;

   public:
    type_(bool is_constant, bool is_assigned) : is_constant(is_constant), is_assigned(is_assigned){};
    type_() : is_constant(0), is_assigned(0){};

    template <class T>
    type<T>* cast() {
        return type_cast<T>(this);
    };

    template <class T>
    type<T>* value_cast() {
        return ::value_cast<T>(this);
    };

    template <class T>
    bool test(void* dummy = nullptr) {
        return cast<T>() != nullptr;
    };

    virtual ~type_(){};
};

template <class T>
class type : public type_ {
   private:
    T value;

   public:
    type(T value, bool is_const = false) : type_(is_const, 1), value(value){};
    type(){};

    T get() { return value; };
};

class Symbol_table {
   protected:
    Symbol_table* parent;
    std::map<std::string, type_*> table;

   public:
    Symbol_table(Symbol_table* parent = nullptr) : parent(parent) {}

    void add(const std::string& name, type_* ty);

    type_* find(const std::string& name);

    type_* find_all(const std::string& name);

    bool visiable(const std::string& name);

    bool visiable(const std::string& first, const std::string& args...);

    bool declare(const std::string& name, type_* ty);

    template <class... Types>
    bool check(const std::string& name, typename std::enable_if<sizeof...(Types) == 0>::type* dummy = nullptr) {
        return false;
    }

    template <class T, class... Types>
    bool check(const std::string& name, void* dummy = nullptr) {
        return (type_cast<T>(this->find(name)) != nullptr)                 /*current scope*/
               || (this->parent && this->parent->check<T, Types...>(name)) /*parent scope*/
               || this->check<Types...>(name);                             /*next type*/
    }
};

int fuck();
